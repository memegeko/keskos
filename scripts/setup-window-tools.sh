#!/usr/bin/env bash
set -euo pipefail

SCRIPT_SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_SOURCE_DIR/lib-ui.sh" ]]; then
  # shellcheck source=scripts/lib-ui.sh
  . "$SCRIPT_SOURCE_DIR/lib-ui.sh"
fi

REPO_DIR="${1:-}"
INSTALL_ROOT="${INSTALL_ROOT:-${ROOT_MOUNT:-${MOUNTPOINT:-/}}}"

log() {
  if declare -F ui_log >/dev/null 2>&1; then
    ui_log "setup-window-tools" "$1"
  else
    printf '[setup-window-tools] %s\n' "$1"
  fi
}

warn() {
  if declare -F ui_warn >/dev/null 2>&1; then
    ui_warn "setup-window-tools" "$1"
  else
    printf '[setup-window-tools] warning: %s\n' "$1" >&2
  fi
}

run_as_root() {
  if [[ ${EUID} -eq 0 ]]; then
    "$@"
  else
    sudo "$@"
  fi
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

  log "yay was not found. Installing yay so kdotool-bin can be pulled from the AUR..."

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

install_kdotool_bin() {
  if command -v kdotool >/dev/null 2>&1; then
    log "kdotool is already available at $(command -v kdotool)."
    return 0
  fi

  if [[ "$INSTALL_ROOT" != "/" ]]; then
    warn "Skipping kdotool-bin installation because INSTALL_ROOT=$INSTALL_ROOT is not the live system root."
    return 0
  fi

  if [[ "${XDG_SESSION_TYPE:-}" != "wayland" && -z "${WAYLAND_DISPLAY:-}" ]]; then
    log "Skipping kdotool-bin because the current session is not Wayland."
    return 0
  fi

  log "Trying to install kdotool-bin for in-launcher Wayland window switching..."

  if command -v paru >/dev/null 2>&1; then
    if paru -S --needed --noconfirm kdotool-bin; then
      log "Installed kdotool-bin with paru."
      return 0
    fi
    warn "paru could not install kdotool-bin."
  fi

  if ! command -v yay >/dev/null 2>&1; then
    install_yay_helper || true
  fi

  if command -v yay >/dev/null 2>&1; then
    if yay -S --needed --noconfirm kdotool-bin; then
      log "Installed kdotool-bin with yay."
      return 0
    fi
    warn "yay could not install kdotool-bin."
  fi

  warn "kdotool-bin could not be installed automatically. Active Windows will stay in the launcher on Wayland only after you install kdotool-bin manually."
  return 0
}

main() {
  install_kdotool_bin
}

main "$@"
