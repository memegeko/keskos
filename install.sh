#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EWW_REF="${KESKOS_EWW_REF:-v0.6.0}"

log() {
  printf '[keskos] %s\n' "$1"
}

warn() {
  printf '[keskos] warning: %s\n' "$1" >&2
}

fail() {
  printf '[keskos] error: %s\n' "$1" >&2
  exit 1
}

require_arch() {
  if ! command -v pacman >/dev/null 2>&1; then
    fail "pacman was not found. keskos only supports Arch Linux."
  fi

  if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    if [[ "${ID:-}" != "arch" && "${ID_LIKE:-}" != *arch* ]]; then
      fail "Unsupported distribution: ${PRETTY_NAME:-unknown}. keskos only supports Arch Linux."
    fi
  fi
}

install_packages() {
  local packages=(
    rofi
    konsole
    dolphin
    fastfetch
    jq
    lm_sensors
    procps-ng
    iproute2
    git
    cargo
    base-devel
    gtk3
    gtk-layer-shell
    pango
    gdk-pixbuf2
    libdbusmenu-gtk3
    cairo
    glib2
    gcc-libs
    ttf-jetbrains-mono-nerd
  )

  if ! command -v sudo >/dev/null 2>&1; then
    fail "sudo is required to install packages."
  fi

  log "Installing runtime and build packages with pacman..."
  sudo pacman -S --needed "${packages[@]}"
}

prepare_directories() {
  log "Creating user-local directories..."
  mkdir -p \
    "$HOME/.config/eww/widgets" \
    "$HOME/.config/rofi" \
    "$HOME/.config/autostart" \
    "$HOME/.local/bin" \
    "$HOME/.local/share/applications" \
    "$HOME/.local/share/color-schemes" \
    "$HOME/.local/share/keskos/assets" \
    "$HOME/.cache/keskos"
}

restart_plasma() {
  if ! command -v plasmashell >/dev/null 2>&1; then
    warn "plasmashell is not available in PATH; skipping shell restart."
    return
  fi

  log "Restarting plasmashell..."

  if command -v kquitapp6 >/dev/null 2>&1; then
    kquitapp6 plasmashell >/dev/null 2>&1 || true
  elif command -v kquitapp5 >/dev/null 2>&1; then
    kquitapp5 plasmashell >/dev/null 2>&1 || true
  else
    pkill -x plasmashell >/dev/null 2>&1 || true
  fi

  sleep 2
  nohup plasmashell >/dev/null 2>&1 &
}

start_hud() {
  if [[ -x "$HOME/.local/bin/keskos-start-eww" ]]; then
    log "Starting the KESKOS Eww HUD..."
    nohup "$HOME/.local/bin/keskos-start-eww" >/dev/null 2>&1 &
  fi
}

main() {
  if [[ ${EUID} -eq 0 ]]; then
    fail "Do not run install.sh as root. Run it as your normal user; sudo is used only for pacman."
  fi

  require_arch
  prepare_directories
  install_packages

  log "Installing rofi launcher assets..."
  bash "$SCRIPT_DIR/scripts/setup-rofi.sh" "$SCRIPT_DIR"

  log "Installing wallpaper assets..."
  bash "$SCRIPT_DIR/scripts/setup-wallpaper.sh" "$SCRIPT_DIR"

  log "Installing Eww Wayland HUD from source (${EWW_REF})..."
  bash "$SCRIPT_DIR/scripts/setup-eww.sh" "$SCRIPT_DIR"

  log "Installing autostart entries..."
  bash "$SCRIPT_DIR/scripts/setup-autostart.sh" "$SCRIPT_DIR"

  log "Installing the launcher shortcut..."
  bash "$SCRIPT_DIR/scripts/setup-shortcuts.sh" "$SCRIPT_DIR"

  log "Applying KDE theme settings..."
  bash "$SCRIPT_DIR/scripts/apply-kde.sh" "$SCRIPT_DIR"

  restart_plasma
  start_hud

  printf '\nKESKOS EWW HUD installed. Log out and back in.\n'
}

main "$@"
