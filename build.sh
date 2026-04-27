#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK_ROOT="${REPO_ROOT}/work"
OUT_DIR="${REPO_ROOT}/out"
STAGE_DIR="${WORK_ROOT}/profile"
ARCHISO_WORK_DIR="${WORK_ROOT}/archiso"
LOCAL_REPO_DIR="${WORK_ROOT}/localrepo/x86_64"
GENERATED_PACMAN_CONF="${WORK_ROOT}/pacman.conf"
AUR_BUILD_ROOT="${WORK_ROOT}/aur"
SOURCE_DATE="${SOURCE_DATE_EPOCH:-$(date +%s)}"
ISO_VERSION="${KESKOS_ISO_VERSION:-$(date --date="@${SOURCE_DATE}" +%Y.%m.%d)}"
AUR_PACKAGES=(calamares kdotool-bin)

log() {
  printf '[keskos-build] %s\n' "$1"
}

warn() {
  printf '[keskos-build] warning: %s\n' "$1" >&2
}

fail() {
  printf '[keskos-build] error: %s\n' "$1" >&2
  exit 1
}

require_command() {
  local command_name="$1"
  command -v "$command_name" >/dev/null 2>&1 || fail "Missing required command: ${command_name}"
}

check_arch_host() {
  [[ -f /etc/os-release ]] || fail "This build script must be run on Arch Linux."
  # shellcheck disable=SC1091
  . /etc/os-release
  [[ "${ID:-}" == "arch" || "${ID_LIKE:-}" == *arch* ]] || fail "This build script must be run on Arch Linux."
  command -v pacman >/dev/null 2>&1 || fail "pacman was not found. This build script must be run on Arch Linux."
}

check_dependencies() {
  local deps=(
    mkarchiso
    makepkg
    repo-add
    grub-install
    syslinux
    curl
    git
    awk
    sed
    install
    bsdtar
    sudo
  )

  for dep in "${deps[@]}"; do
    require_command "$dep"
  done
}

prepare_workdirs() {
  mkdir -p "$WORK_ROOT" "$OUT_DIR" "$AUR_BUILD_ROOT" "$LOCAL_REPO_DIR"
  rm -rf "$STAGE_DIR" "$ARCHISO_WORK_DIR" "$LOCAL_REPO_DIR"
  mkdir -p "$STAGE_DIR" "$ARCHISO_WORK_DIR"
  mkdir -p "$LOCAL_REPO_DIR"
}

build_aur_package() {
  local package_name="$1"
  local package_dir="${AUR_BUILD_ROOT}/${package_name}"
  local pkgdest="${WORK_ROOT}/pkgdest"

  mkdir -p "$pkgdest"

  if [[ ! -d "$package_dir/.git" ]]; then
    log "Cloning AUR package ${package_name}..."
    git clone "https://aur.archlinux.org/${package_name}.git" "$package_dir"
  else
    log "Refreshing AUR package ${package_name}..."
    git -C "$package_dir" fetch origin
    git -C "$package_dir" reset --hard origin/master
  fi

  log "Building ${package_name} for the local ISO repository..."
  (
    cd "$package_dir"
    PKGDEST="${pkgdest}" makepkg --syncdeps --needed --noconfirm --cleanbuild --clean
  )

  find "$pkgdest" -maxdepth 1 -type f -name "${package_name}-*.pkg.tar.*" -exec cp -f {} "$LOCAL_REPO_DIR/" \;
}

refresh_local_repo() {
  log "Refreshing the local pacman repository..."
  rm -f "${LOCAL_REPO_DIR}"/keskos-local.db* "${LOCAL_REPO_DIR}"/keskos-local.files*
  repo-add "${LOCAL_REPO_DIR}/keskos-local.db.tar.gz" "${LOCAL_REPO_DIR}"/*.pkg.tar.*
}

generate_pacman_conf() {
  local local_repo_uri=""
  log "Generating a pacman.conf that points at the local Calamares repository..."
  local_repo_uri="$(python3 -c 'from pathlib import Path; import sys; print(Path(sys.argv[1]).resolve().as_uri())' "${LOCAL_REPO_DIR}")"
  sed "s|__KESKOS_LOCAL_REPO_URI__|${local_repo_uri}|g" \
    "${REPO_ROOT}/pacman.conf" >"${GENERATED_PACMAN_CONF}"
}

stage_profile_basics() {
  log "Staging the Archiso profile..."
  cp -a "${REPO_ROOT}/airootfs" "${STAGE_DIR}/"
  cp -a "${REPO_ROOT}/grub" "${STAGE_DIR}/"
  cp -a "${REPO_ROOT}/syslinux" "${STAGE_DIR}/"
  cp -a "${REPO_ROOT}/efiboot" "${STAGE_DIR}/"
  install -m 644 "${REPO_ROOT}/profiledef.sh" "${STAGE_DIR}/profiledef.sh"
  install -m 644 "${REPO_ROOT}/packages.x86_64" "${STAGE_DIR}/packages.x86_64"
}

stage_source_tree() {
  local source_root="${STAGE_DIR}/airootfs/usr/local/share/keskos/source"
  mkdir -p "$source_root"

  cp -a "${REPO_ROOT}/assets" "$source_root/"
  cp -a "${REPO_ROOT}/configs" "$source_root/"
  cp -a "${REPO_ROOT}/launcher" "$source_root/"
  cp -a "${REPO_ROOT}/desktop" "$source_root/"
  cp -a "${REPO_ROOT}/browser-home" "$source_root/"
  install -m 644 "${REPO_ROOT}/spinner.png" "$source_root/spinner.png"
  install -m 644 "${REPO_ROOT}/kesk_os_logo_text.png" "$source_root/kesk_os_logo_text.png"
  install -m 644 "${REPO_ROOT}/kesk_os_logo-removebg.png" "$source_root/kesk_os_logo-removebg.png"
}

stage_live_system_assets() {
  local root="${STAGE_DIR}/airootfs"

  mkdir -p \
    "${root}/usr/share/konsole" \
    "${root}/usr/share/color-schemes" \
    "${root}/usr/share/backgrounds/keskos" \
    "${root}/usr/share/plasma/look-and-feel/com.keskos.desktop" \
    "${root}/usr/share/plasma/shells/org.kde.plasma.desktop/contents/lockscreen/assets" \
    "${root}/usr/share/sddm/themes/keskos/assets" \
    "${root}/usr/share/keskos/browser-home" \
    "${root}/usr/share/calamares/branding/keskos" \
    "${root}/etc/calamares/modules"

  install -m 644 "${REPO_ROOT}/configs/konsole/KeskOS.colorscheme" "${root}/usr/share/konsole/KeskOS.colorscheme"
  install -m 644 "${REPO_ROOT}/configs/konsole/KeskOS.profile" "${root}/usr/share/konsole/KeskOS.profile"
  install -m 644 "${REPO_ROOT}/configs/kde/keskos.colors" "${root}/usr/share/color-schemes/KESKOS.colors"

  install -m 644 "${REPO_ROOT}/assets/wallpaper.svg" "${root}/usr/share/backgrounds/keskos/wallpaper.svg"
  install -m 644 "${REPO_ROOT}/assets/wallpaper-1920x1080.png" "${root}/usr/share/backgrounds/keskos/wallpaper-1920x1080.png"
  install -m 644 "${REPO_ROOT}/assets/wallpaper-2560x1440.png" "${root}/usr/share/backgrounds/keskos/wallpaper-2560x1440.png"
  install -m 644 "${REPO_ROOT}/assets/wallpaper-4096x2160.png" "${root}/usr/share/backgrounds/keskos/wallpaper-4096x2160.png"
  install -m 644 "${REPO_ROOT}/assets/kesk_os_logo_text.png" "${root}/usr/share/backgrounds/keskos/kesk_os_logo_text.png"

  cp -a "${REPO_ROOT}/configs/look-and-feel/com.keskos.desktop/." "${root}/usr/share/plasma/look-and-feel/com.keskos.desktop/"
  install -m 644 "${REPO_ROOT}/configs/look-and-feel/com.keskos.desktop/contents/lockscreen/assets/background.png" "${root}/usr/share/plasma/shells/org.kde.plasma.desktop/contents/lockscreen/assets/background.png"
  install -m 644 "${REPO_ROOT}/configs/look-and-feel/com.keskos.desktop/contents/lockscreen/assets/logo.png" "${root}/usr/share/plasma/shells/org.kde.plasma.desktop/contents/lockscreen/assets/logo.png"

  install -m 644 "${REPO_ROOT}/configs/sddm/keskos/Main.qml" "${root}/usr/share/sddm/themes/keskos/Main.qml"
  install -m 644 "${REPO_ROOT}/configs/sddm/keskos/metadata.desktop" "${root}/usr/share/sddm/themes/keskos/metadata.desktop"
  install -m 644 "${REPO_ROOT}/configs/sddm/keskos/theme.conf" "${root}/usr/share/sddm/themes/keskos/theme.conf"
  install -m 644 "${REPO_ROOT}/assets/wallpaper-2560x1440.png" "${root}/usr/share/sddm/themes/keskos/assets/background.png"
  install -m 644 "${REPO_ROOT}/kesk_os_logo_text.png" "${root}/usr/share/sddm/themes/keskos/assets/logo.png"

  cp -a "${REPO_ROOT}/browser-home/." "${root}/usr/share/keskos/browser-home/"

  install -m 644 "${REPO_ROOT}/calamares/settings.conf" "${root}/etc/calamares/settings.conf"
  cp -a "${REPO_ROOT}/calamares/modules/." "${root}/etc/calamares/modules/"
  cp -a "${REPO_ROOT}/calamares/branding/keskos/." "${root}/usr/share/calamares/branding/keskos/"
}

stage_application_entries() {
  local root="${STAGE_DIR}/airootfs"
  mkdir -p "${root}/usr/share/applications" "${root}/etc/skel/Desktop"

  cp -a "${REPO_ROOT}/desktop/." "${root}/usr/share/applications/"
  install -m 644 "${REPO_ROOT}/airootfs/usr/share/applications/install-keskos.desktop" "${root}/usr/share/applications/install-keskos.desktop"
  install -m 755 "${REPO_ROOT}/airootfs/etc/skel/Desktop/Install KeskOS.desktop" "${root}/etc/skel/Desktop/Install KeskOS.desktop"
}

stage_boot_branding() {
  log "Adjusting the profile version metadata..."
  sed -i "s/__KESKOS_ISO_VERSION__/${ISO_VERSION}/g" "${STAGE_DIR}/profiledef.sh"
}

run_mkarchiso() {
  log "Building the KeskOS ISO with mkarchiso..."
  sudo mkarchiso \
    -v \
    -C "${GENERATED_PACMAN_CONF}" \
    -w "${ARCHISO_WORK_DIR}" \
    -o "${OUT_DIR}" \
    "${STAGE_DIR}"
}

main() {
  check_arch_host
  check_dependencies
  if (( EUID == 0 )); then
    fail "Run build.sh as a regular user. The script will call sudo only for mkarchiso."
  fi

  prepare_workdirs

  for package_name in "${AUR_PACKAGES[@]}"; do
    build_aur_package "$package_name"
  done

  refresh_local_repo
  generate_pacman_conf
  stage_profile_basics
  stage_source_tree
  stage_live_system_assets
  stage_application_entries
  stage_boot_branding
  run_mkarchiso

  log "KeskOS ISO build complete."
  log "Output directory: ${OUT_DIR}"
}

main "$@"
