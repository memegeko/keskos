#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_WIDGETS_ANSWER="${KESKOS_INSTALL_WIDGETS:-}"
INSTALL_LIBREWOLF_ANSWER="${KESKOS_INSTALL_LIBREWOLF:-}"

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

install_base_packages() {
  local packages=(
    rofi
    konsole
    dolphin
    fastfetch
    python
    python-pyxdg
    ttf-jetbrains-mono-nerd
    wl-clipboard
    xclip
    wmctrl
  )

  if ! command -v sudo >/dev/null 2>&1; then
    fail "sudo is required to install packages."
  fi

  log "Installing base packages with pacman..."
  sudo pacman -S --needed "${packages[@]}"
}

prepare_directories() {
  log "Creating user-local directories..."
  mkdir -p \
    "$HOME/.config/rofi" \
    "$HOME/.config/autostart" \
    "$HOME/.local/bin" \
    "$HOME/.local/share/applications" \
    "$HOME/.local/share/color-schemes" \
    "$HOME/.local/share/keskos/assets" \
    "$HOME/.cache/keskos"
}

prompt_widget_install() {
  local answer=""

  if [[ -n "$INSTALL_WIDGETS_ANSWER" ]]; then
    answer="$INSTALL_WIDGETS_ANSWER"
  else
    echo "Install KeskOS HUD widgets? (y/n)"
    read -r answer
  fi

  case "${answer,,}" in
    y|yes)
      INSTALL_WIDGETS_ANSWER="y"
      ;;
    *)
      INSTALL_WIDGETS_ANSWER="n"
      ;;
  esac
}

prompt_librewolf_install() {
  local answer=""

  if [[ -n "$INSTALL_LIBREWOLF_ANSWER" ]]; then
    answer="$INSTALL_LIBREWOLF_ANSWER"
  else
    printf 'Do you want to install the Kesk OS themed LibreWolf browser? [y/N]\n'
    read -r answer
  fi

  case "${answer,,}" in
    y|yes)
      INSTALL_LIBREWOLF_ANSWER="y"
      ;;
    *)
      INSTALL_LIBREWOLF_ANSWER="n"
      ;;
  esac
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

start_quickshell_hud() {
  if [[ "$INSTALL_WIDGETS_ANSWER" != "y" ]]; then
    return
  fi

  if [[ -x "$HOME/.local/bin/keskos-start-quickshell" ]]; then
    log "Starting the KeskOS Quickshell HUD..."
    nohup "$HOME/.local/bin/keskos-start-quickshell" >/dev/null 2>&1 &
  fi
}

stop_old_widget_processes() {
  if [[ "$INSTALL_WIDGETS_ANSWER" == "y" ]]; then
    return
  fi

  pkill -x quickshell >/dev/null 2>&1 || true
  pkill -x eww >/dev/null 2>&1 || true
}

main() {
  if [[ ${EUID} -eq 0 ]]; then
    fail "Do not run install.sh as root. Run it as your normal user; sudo is used only for pacman."
  fi

  require_arch
  prepare_directories
  install_base_packages
  prompt_widget_install
  prompt_librewolf_install

  log "Installing optional window-control helpers..."
  bash "$SCRIPT_DIR/scripts/setup-window-tools.sh" "$SCRIPT_DIR"

  log "Installing rofi launcher assets..."
  bash "$SCRIPT_DIR/scripts/setup-rofi.sh" "$SCRIPT_DIR"

  log "Installing wallpaper assets..."
  bash "$SCRIPT_DIR/scripts/setup-wallpaper.sh" "$SCRIPT_DIR"

  if [[ "$INSTALL_WIDGETS_ANSWER" == "y" ]]; then
    log "Installing the optional Quickshell HUD..."
    bash "$SCRIPT_DIR/scripts/setup-quickshell.sh" "$SCRIPT_DIR"
  else
    log "Skipping widget installation and keeping minimal mode."
  fi

  if [[ "$INSTALL_LIBREWOLF_ANSWER" == "y" ]]; then
    log "Installing the optional Kesk OS LibreWolf browser layer..."
    if ! bash "$SCRIPT_DIR/scripts/setup-librewolf.sh" "$SCRIPT_DIR"; then
      warn "LibreWolf setup did not complete cleanly. Continuing with the rest of the install."
    fi
  else
    log "Skipping LibreWolf installation and theming."
  fi

  log "Installing autostart entries..."
  bash "$SCRIPT_DIR/scripts/setup-autostart.sh" "$SCRIPT_DIR" "$INSTALL_WIDGETS_ANSWER"

  log "Installing the launcher shortcut..."
  bash "$SCRIPT_DIR/scripts/setup-shortcuts.sh" "$SCRIPT_DIR"

  log "Applying KDE theme settings..."
  bash "$SCRIPT_DIR/scripts/apply-kde.sh" "$SCRIPT_DIR"

  restart_plasma
  stop_old_widget_processes
  start_quickshell_hud

  printf '\nKESKOS setup complete.\n'
  if [[ "$INSTALL_WIDGETS_ANSWER" == "y" ]]; then
    printf 'If widgets enabled: Quickshell HUD active.\n'
  else
    printf 'If disabled: running minimal mode.\n'
  fi
}

main "$@"
