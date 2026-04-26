#!/usr/bin/env bash
set -euo pipefail

SCRIPT_SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_SOURCE_DIR/lib-ui.sh" ]]; then
  # shellcheck source=scripts/lib-ui.sh
  . "$SCRIPT_SOURCE_DIR/lib-ui.sh"
fi

REPO_DIR="${1:?usage: setup-librewolf.sh /path/to/repo}"
CURRENT_USER="$(id -un)"
TARGET_USER="${TARGET_USER:-$CURRENT_USER}"
INSTALL_ROOT="${INSTALL_ROOT:-${ROOT_MOUNT:-${MOUNTPOINT:-/}}}"
TARGET_HOME="${TARGET_HOME:-}"
TARGET_UID=""
TARGET_GID=""
HOMEPAGE_URL="file:///usr/share/kesk/browser-home/index.html"

log() {
  if declare -F ui_log >/dev/null 2>&1; then
    ui_log "setup-librewolf" "$1"
  else
    printf '[setup-librewolf] %s\n' "$1"
  fi
}

warn() {
  if declare -F ui_warn >/dev/null 2>&1; then
    ui_warn "setup-librewolf" "$1"
  else
    printf '[setup-librewolf] warning: %s\n' "$1" >&2
  fi
}

backup_file() {
  local file_path="$1"

  if [[ -f "$file_path" && ! -f "${file_path}.keskos.bak" ]]; then
    cp "$file_path" "${file_path}.keskos.bak" 2>/dev/null || run_as_root cp "$file_path" "${file_path}.keskos.bak"
  fi
}

run_as_root() {
  if [[ ${EUID} -eq 0 ]]; then
    "$@"
  else
    sudo "$@"
  fi
}

resolve_target_home() {
  if [[ -n "$TARGET_HOME" ]]; then
    if [[ -d "$TARGET_HOME" ]]; then
      TARGET_UID="$(stat -c '%u' "$TARGET_HOME" 2>/dev/null || true)"
      TARGET_GID="$(stat -c '%g' "$TARGET_HOME" 2>/dev/null || true)"
    fi
    return
  fi

  if [[ "$INSTALL_ROOT" != "/" && -d "$INSTALL_ROOT/home/$TARGET_USER" ]]; then
    TARGET_HOME="$INSTALL_ROOT/home/$TARGET_USER"
    TARGET_UID="$(stat -c '%u' "$TARGET_HOME" 2>/dev/null || true)"
    TARGET_GID="$(stat -c '%g' "$TARGET_HOME" 2>/dev/null || true)"
    return
  fi

  if getent passwd "$TARGET_USER" >/dev/null 2>&1; then
    TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
    TARGET_UID="$(stat -c '%u' "$TARGET_HOME" 2>/dev/null || true)"
    TARGET_GID="$(stat -c '%g' "$TARGET_HOME" 2>/dev/null || true)"
    return
  fi

  if [[ "$TARGET_USER" == "$CURRENT_USER" ]]; then
    TARGET_HOME="$HOME"
    TARGET_UID="$(stat -c '%u' "$TARGET_HOME" 2>/dev/null || true)"
    TARGET_GID="$(stat -c '%g' "$TARGET_HOME" 2>/dev/null || true)"
    return
  fi

  TARGET_HOME="$HOME"
  TARGET_UID="$(stat -c '%u' "$TARGET_HOME" 2>/dev/null || true)"
  TARGET_GID="$(stat -c '%g' "$TARGET_HOME" 2>/dev/null || true)"
  warn "Falling back to the current HOME because no home directory could be resolved for $TARGET_USER."
}

create_target_dir() {
  local dir_path="$1"
  local install_args=(install -d)

  if [[ "$TARGET_USER" == "$CURRENT_USER" && "$TARGET_HOME" == "$HOME" && "$INSTALL_ROOT" == "/" ]]; then
    mkdir -p "$dir_path"
    return
  fi

  if [[ -n "$TARGET_UID" ]]; then
    install_args+=(-o "$TARGET_UID")
  fi

  if [[ -n "$TARGET_GID" ]]; then
    install_args+=(-g "$TARGET_GID")
  fi

  install_args+=("$dir_path")
  run_as_root "${install_args[@]}"
}

install_target_file() {
  local source_path="$1"
  local target_path="$2"
  local mode="${3:-644}"
  local install_args=(install -m "$mode")

  if [[ "$TARGET_USER" == "$CURRENT_USER" && "$TARGET_HOME" == "$HOME" && "$INSTALL_ROOT" == "/" ]]; then
    install -m "$mode" "$source_path" "$target_path"
    return
  fi

  if [[ -n "$TARGET_UID" ]]; then
    install_args+=(-o "$TARGET_UID")
  fi

  if [[ -n "$TARGET_GID" ]]; then
    install_args+=(-g "$TARGET_GID")
  fi

  install_args+=("$source_path" "$target_path")
  run_as_root "${install_args[@]}"
}

librewolf_command_path() {
  local candidates=(
    "librewolf"
    "$INSTALL_ROOT/usr/bin/librewolf"
    "$INSTALL_ROOT/opt/librewolf/librewolf"
  )
  local candidate

  for candidate in "${candidates[@]}"; do
    if [[ "$candidate" == "librewolf" ]]; then
      if command -v librewolf >/dev/null 2>&1; then
        command -v librewolf
        return 0
      fi
      continue
    fi

    if [[ -x "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  return 1
}

resolve_profile_path() {
  local profile_root="$1"
  local raw_path="$2"

  if [[ -z "$raw_path" ]]; then
    return 1
  fi

  if [[ "$raw_path" = /* ]]; then
    printf '%s\n' "$raw_path"
  else
    printf '%s\n' "$profile_root/$raw_path"
  fi
}

target_config_home() {
  if [[ -n "${TARGET_CONFIG_HOME:-}" ]]; then
    printf '%s\n' "$TARGET_CONFIG_HOME"
    return
  fi

  if [[ "$TARGET_USER" == "$CURRENT_USER" && -n "${XDG_CONFIG_HOME:-}" ]]; then
    printf '%s\n' "$XDG_CONFIG_HOME"
    return
  fi

  printf '%s\n' "$TARGET_HOME/.config"
}

profile_root_candidates() {
  local config_home=""

  config_home="$(target_config_home)"
  printf '%s\n' "$TARGET_HOME/.librewolf"
  printf '%s\n' "$config_home/librewolf/librewolf"

  if [[ -d "$TARGET_HOME/.var/app/io.gitlab.librewolf-community/.librewolf" ]]; then
    printf '%s\n' "$TARGET_HOME/.var/app/io.gitlab.librewolf-community/.librewolf"
  fi
}

find_profile_from_profiles_ini() {
  local profile_root="$1"
  local profiles_ini="$profile_root/profiles.ini"
  local candidate=""
  local path_value=""

  [[ -f "$profiles_ini" ]] || return 1

  path_value="$(
    awk -F= '
      /^\[Install/ { in_install = 1; next }
      /^\[/ && $0 !~ /^\[Install/ { in_install = 0 }
      in_install && $1 == "Default" { print $2; exit }
    ' "$profiles_ini"
  )"

  if [[ -n "$path_value" ]]; then
    candidate="$(resolve_profile_path "$profile_root" "$path_value")"
    if [[ -d "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  fi

  path_value="$(
    awk -F= '
      function flush_profile() {
        if (profile_path != "" && profile_default == "1" && chosen == "") {
          chosen = profile_path
        }
      }
      /^\[Profile/ {
        flush_profile()
        in_profile = 1
        profile_path = ""
        profile_default = "0"
        next
      }
      /^\[/ && $0 !~ /^\[Profile/ {
        flush_profile()
        in_profile = 0
        next
      }
      in_profile && $1 == "Path" { profile_path = $2 }
      in_profile && $1 == "Default" { profile_default = $2 }
      END {
        flush_profile()
        if (chosen != "") {
          print chosen
        }
      }
    ' "$profiles_ini"
  )"

  if [[ -n "$path_value" ]]; then
    candidate="$(resolve_profile_path "$profile_root" "$path_value")"
    if [[ -d "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  fi

  path_value="$(
    awk -F= '
      /^\[Profile/ { in_profile = 1; next }
      /^\[/ && $0 !~ /^\[Profile/ { in_profile = 0; next }
      in_profile && $1 == "Path" { print $2; exit }
    ' "$profiles_ini"
  )"

  if [[ -n "$path_value" ]]; then
    candidate="$(resolve_profile_path "$profile_root" "$path_value")"
    if [[ -d "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  fi

  return 1
}

find_librewolf_profiles() {
  local patterns=(
    "*.default-release*"
    "*.default-default*"
    "*.default*"
  )
  local roots=()
  local root=""
  local pattern=""
  local candidate=""
  local -A seen=()

  while IFS= read -r root; do
    [[ -n "$root" ]] || continue
    roots+=("$root")
  done < <(profile_root_candidates)

  shopt -s nullglob
  for root in "${roots[@]}"; do
    [[ -d "$root" ]] || continue

    candidate="$(find_profile_from_profiles_ini "$root" || true)"
    if [[ -n "$candidate" && -d "$candidate" && -z "${seen["$candidate"]+x}" ]]; then
      printf '%s\n' "$candidate"
      seen["$candidate"]=1
    fi

    for pattern in "${patterns[@]}"; do
      for candidate in "$root"/$pattern; do
        if [[ -d "$candidate" && -z "${seen["$candidate"]+x}" ]]; then
          printf '%s\n' "$candidate"
          seen["$candidate"]=1
        fi
      done
    done
  done
  shopt -u nullglob
}

run_as_target_user() {
  if [[ "$INSTALL_ROOT" != "/" ]]; then
    warn "Skipping profile-side LibreWolf commands because INSTALL_ROOT=$INSTALL_ROOT is an offline target root."
    return 1
  fi

  if [[ "$TARGET_USER" == "$CURRENT_USER" && "$TARGET_HOME" == "$HOME" ]]; then
    HOME="$TARGET_HOME" "$@"
    return
  fi

  if ! command -v sudo >/dev/null 2>&1; then
    warn "sudo is required to run LibreWolf as $TARGET_USER."
    return 1
  fi

  sudo -u "$TARGET_USER" env HOME="$TARGET_HOME" "$@"
}

run_as_target_user_timeout() {
  local seconds="$1"
  shift

  if [[ "$INSTALL_ROOT" != "/" ]]; then
    warn "Skipping timed LibreWolf commands because INSTALL_ROOT=$INSTALL_ROOT is an offline target root."
    return 1
  fi

  if ! command -v timeout >/dev/null 2>&1; then
    run_as_target_user "$@"
    return
  fi

  if [[ "$TARGET_USER" == "$CURRENT_USER" && "$TARGET_HOME" == "$HOME" ]]; then
    HOME="$TARGET_HOME" timeout --signal=TERM --kill-after=5 "$seconds" "$@"
    return
  fi

  if ! command -v sudo >/dev/null 2>&1; then
    warn "sudo is required to run timed LibreWolf commands as $TARGET_USER."
    return 1
  fi

  sudo -u "$TARGET_USER" env HOME="$TARGET_HOME" timeout --signal=TERM --kill-after=5 "$seconds" "$@"
}

install_yay_helper() {
  local build_root=""
  local build_dir=""

  if command -v yay >/dev/null 2>&1; then
    return 0
  fi

  if [[ "$INSTALL_ROOT" != "/" ]]; then
    warn "INSTALL_ROOT=$INSTALL_ROOT is not the live system root. Skipping automatic yay installation."
    return 1
  fi

  if ! command -v sudo >/dev/null 2>&1; then
    warn "sudo is required to install yay automatically."
    return 1
  fi

  log "yay was not found. Installing yay so LibreWolf can be pulled from the AUR..."

  if ! run_as_root pacman -S --needed --noconfirm git base-devel; then
    warn "Could not install the git/base-devel packages required to build yay."
    return 1
  fi

  build_root="${HOME}/.cache/keskos"
  mkdir -p "$build_root"
  build_dir="$(mktemp -d "$build_root/yay-build.XXXXXX")"

  if ! git clone --depth 1 https://aur.archlinux.org/yay-bin.git "$build_dir/yay-bin" >/dev/null 2>&1; then
    warn "Could not clone yay-bin from the AUR."
    rm -rf "$build_dir"
    return 1
  fi

  if ! (
    cd "$build_dir/yay-bin"
    makepkg -si --noconfirm --needed
  ); then
    warn "Building or installing yay-bin failed."
    rm -rf "$build_dir"
    return 1
  fi

  rm -rf "$build_dir"

  if ! command -v yay >/dev/null 2>&1; then
    warn "yay installation finished without making the yay command available in PATH."
    return 1
  fi

  log "Installed yay successfully."
  return 0
}

install_librewolf_package() {
  if [[ "$INSTALL_ROOT" != "/" ]]; then
    warn "INSTALL_ROOT=$INSTALL_ROOT is not the live system root. Skipping automatic LibreWolf package installation."
    return 1
  fi

  if librewolf_command_path >/dev/null 2>&1; then
    log "LibreWolf is already available."
    return 0
  fi

  if command -v paru >/dev/null 2>&1; then
    log "Installing LibreWolf with paru..."
    if paru -S --needed --noconfirm librewolf-bin; then
      return 0
    fi
    warn "paru could not install librewolf-bin."
  fi

  if command -v yay >/dev/null 2>&1; then
    log "Installing LibreWolf with yay..."
    if yay -S --needed --noconfirm librewolf-bin; then
      return 0
    fi
    warn "yay could not install librewolf-bin."
  elif install_yay_helper; then
    log "Installing LibreWolf with the newly installed yay..."
    if yay -S --needed --noconfirm librewolf-bin; then
      return 0
    fi
    warn "yay was installed, but it still could not install librewolf-bin."
  fi

  if pacman -Si librewolf >/dev/null 2>&1; then
    log "Installing LibreWolf with pacman..."
    if run_as_root pacman -S --needed --noconfirm librewolf; then
      return 0
    fi
    warn "pacman could not install librewolf."
  fi

  warn "LibreWolf could not be installed automatically. Continuing with the rest of the keskos install."
  return 1
}

install_kesk_librewolf_homepage() {
  local target_dir="$INSTALL_ROOT/usr/share/kesk/browser-home"

  run_as_root install -d "$target_dir"
  run_as_root install -Dm644 "$REPO_DIR/kesk-librewolf/homepage/index.html" "$target_dir/index.html"
  run_as_root install -Dm644 "$REPO_DIR/kesk-librewolf/homepage/style.css" "$target_dir/style.css"
  run_as_root install -Dm644 "$REPO_DIR/kesk-librewolf/homepage/script.js" "$target_dir/script.js"

  log "Installed the offline Kesk OS LibreWolf homepage to $target_dir."
}

install_kesk_librewolf_policies() {
  local policy_candidates=()
  local fallback_target="$INSTALL_ROOT/usr/lib/librewolf/distribution/policies.json"
  local candidate_path

  if [[ -d "$INSTALL_ROOT/usr/lib/librewolf" || ! -d "$INSTALL_ROOT/opt/librewolf" ]]; then
    policy_candidates+=("$INSTALL_ROOT/usr/lib/librewolf/distribution/policies.json")
  fi

  if [[ -d "$INSTALL_ROOT/opt/librewolf" ]]; then
    policy_candidates+=("$INSTALL_ROOT/opt/librewolf/distribution/policies.json")
  fi

  if [[ ${#policy_candidates[@]} -eq 0 ]]; then
    policy_candidates+=("$fallback_target")
  fi

  for candidate_path in "${policy_candidates[@]}"; do
    run_as_root install -Dm644 "$REPO_DIR/kesk-librewolf/policies/policies.json" "$candidate_path"
    log "Installed LibreWolf policies to $candidate_path."
  done
}

find_librewolf_profile() {
  local candidate

  while IFS= read -r candidate; do
    if [[ -n "$candidate" && -d "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done < <(find_librewolf_profiles)

  return 1
}

create_librewolf_profile() {
  local librewolf_bin="$1"

  if [[ "$INSTALL_ROOT" != "/" ]]; then
    warn "Skipping automatic profile creation for offline target root $INSTALL_ROOT."
    return 1
  fi

  log "No LibreWolf profile was found. Trying the profile creation command first..."
  run_as_target_user "$librewolf_bin" -CreateProfile default-release >/dev/null 2>&1 || \
    run_as_target_user "$librewolf_bin" --CreateProfile default-release >/dev/null 2>&1 || true

  if find_librewolf_profile >/dev/null 2>&1; then
    return 0
  fi

  log "Profile creation command did not produce a visible profile. Trying a bounded headless first-run..."
  run_as_target_user_timeout 15 "$librewolf_bin" --headless about:blank >/dev/null 2>&1 || true

  if [[ "$TARGET_USER" == "$CURRENT_USER" && "$TARGET_HOME" == "$HOME" ]]; then
    pkill -x librewolf >/dev/null 2>&1 || true
  else
    run_as_root pkill -u "$TARGET_USER" -x librewolf >/dev/null 2>&1 || true
  fi

  find_librewolf_profile >/dev/null 2>&1
}

write_user_js_block() {
  local profile_dir="$1"
  local user_js="$profile_dir/user.js"
  local tmp_file

  backup_file "$user_js"
  tmp_file="$(mktemp)"

  if [[ -f "$user_js" ]]; then
    if ! awk '
      BEGIN { skip = 0 }
      /^\/\/ KESKOS LIBREWOLF BEGIN$/ { skip = 1; next }
      /^\/\/ KESKOS LIBREWOLF END$/ { skip = 0; next }
      skip == 0 { print }
    ' "$user_js" >"$tmp_file" 2>/dev/null; then
      run_as_root cat "$user_js" | awk '
        BEGIN { skip = 0 }
        /^\/\/ KESKOS LIBREWOLF BEGIN$/ { skip = 1; next }
        /^\/\/ KESKOS LIBREWOLF END$/ { skip = 0; next }
        skip == 0 { print }
      ' >"$tmp_file"
    fi
  fi

  cat >>"$tmp_file" <<EOF
// KESKOS LIBREWOLF BEGIN
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
user_pref("browser.startup.page", 1);
user_pref("browser.startup.homepage", "$HOMEPAGE_URL");
user_pref("startup.homepage_welcome_url", "");
user_pref("startup.homepage_welcome_url.additional", "");
user_pref("browser.aboutwelcome.enabled", false);
user_pref("browser.shell.checkDefaultBrowser", false);
// KESKOS LIBREWOLF END
EOF

  install_target_file "$tmp_file" "$user_js" 644
  rm -f "$tmp_file"
}

install_librewolf_overrides() {
  local config_home=""
  local override_roots=()
  local root=""
  local override_path=""
  local tmp_file=""
  local -A seen=()

  config_home="$(target_config_home)"
  override_roots+=("$TARGET_HOME/.librewolf")
  override_roots+=("$config_home/librewolf/librewolf")

  if [[ -d "$TARGET_HOME/.var/app/io.gitlab.librewolf-community/.librewolf" ]]; then
    override_roots+=("$TARGET_HOME/.var/app/io.gitlab.librewolf-community/.librewolf")
  fi

  tmp_file="$(mktemp)"
  cat >"$tmp_file" <<EOF
// KESKOS LIBREWOLF OVERRIDES BEGIN
pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
defaultPref("browser.startup.page", 1);
defaultPref("browser.startup.homepage", "$HOMEPAGE_URL");
defaultPref("startup.homepage_welcome_url", "");
defaultPref("startup.homepage_welcome_url.additional", "");
defaultPref("browser.aboutwelcome.enabled", false);
defaultPref("browser.shell.checkDefaultBrowser", false);
// KESKOS LIBREWOLF OVERRIDES END
EOF

  for root in "${override_roots[@]}"; do
    [[ -n "$root" ]] || continue
    if [[ -n "${seen["$root"]+x}" ]]; then
      continue
    fi
    seen["$root"]=1

    create_target_dir "$root"
    override_path="$root/librewolf.overrides.cfg"
    backup_file "$override_path"
    install_target_file "$tmp_file" "$override_path" 644
    log "Installed LibreWolf overrides to $override_path."
  done

  rm -f "$tmp_file"
}

install_kesk_librewolf_theme() {
  local profile_dir="$1"
  local chrome_dir="$profile_dir/chrome"

  create_target_dir "$chrome_dir"

  backup_file "$chrome_dir/userChrome.css"
  backup_file "$chrome_dir/userContent.css"

  install_target_file "$REPO_DIR/kesk-librewolf/chrome/userChrome.css" "$chrome_dir/userChrome.css" 644
  install_target_file "$REPO_DIR/kesk-librewolf/chrome/userContent.css" "$chrome_dir/userContent.css" 644

  log "Installed userChrome.css and userContent.css into $chrome_dir."
}

configure_librewolf_profile() {
  local librewolf_bin="$1"
  local profile_dir=""
  local profiles=()

  if [[ ! -d "$TARGET_HOME" ]]; then
    warn "Target home $TARGET_HOME does not exist. Skipping LibreWolf profile theming."
    return 1
  fi

  profile_dir="$(find_librewolf_profile || true)"
  if [[ -z "$profile_dir" ]]; then
    if ! create_librewolf_profile "$librewolf_bin"; then
      warn "Could not create a LibreWolf profile automatically. Launch LibreWolf once, then rerun scripts/setup-librewolf.sh."
      return 1
    fi
    profile_dir="$(find_librewolf_profile || true)"
  fi

  if [[ -z "$profile_dir" ]]; then
    warn "LibreWolf profile discovery still failed under the known LibreWolf profile roots."
    return 1
  fi

  while IFS= read -r profile_dir; do
    [[ -n "$profile_dir" ]] || continue
    profiles+=("$profile_dir")
  done < <(find_librewolf_profiles)

  if [[ ${#profiles[@]} -eq 0 ]]; then
    profiles+=("$profile_dir")
  fi

  for profile_dir in "${profiles[@]}"; do
    install_kesk_librewolf_theme "$profile_dir"
    write_user_js_block "$profile_dir"
    log "Configured the LibreWolf profile at $profile_dir."
  done

  if pgrep -x librewolf >/dev/null 2>&1; then
    warn "LibreWolf is running. Restart it once to load the new theme and homepage settings."
  fi
}

main() {
  local librewolf_bin=""

  resolve_target_home
  log "Target user: $TARGET_USER"
  log "Target home: $TARGET_HOME"
  log "Install root: $INSTALL_ROOT"

  if ! install_librewolf_package; then
    warn "Continuing without a verified LibreWolf package install."
  fi

  if ! install_kesk_librewolf_homepage; then
    warn "Could not install the Kesk OS LibreWolf homepage files."
  fi

  if ! install_kesk_librewolf_policies; then
    warn "Could not install LibreWolf policy files."
  fi

  if ! install_librewolf_overrides; then
    warn "Could not install LibreWolf override files."
  fi

  librewolf_bin="$(librewolf_command_path || true)"
  if [[ -z "$librewolf_bin" ]]; then
    warn "LibreWolf is not available in PATH yet, so profile theming is being skipped."
    return 0
  fi

  if ! configure_librewolf_profile "$librewolf_bin"; then
    warn "LibreWolf profile theming did not complete automatically."
  fi

  log "LibreWolf setup finished."
}

main "$@"
