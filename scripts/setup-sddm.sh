#!/usr/bin/env bash
set -euo pipefail

SCRIPT_SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_SOURCE_DIR/lib-ui.sh" ]]; then
  # shellcheck source=scripts/lib-ui.sh
  . "$SCRIPT_SOURCE_DIR/lib-ui.sh"
fi

REPO_DIR="${1:?usage: setup-sddm.sh /path/to/repo}"

log() {
  if declare -F ui_log >/dev/null 2>&1; then
    ui_log "setup-sddm" "$1"
  else
    printf '[setup-sddm] %s\n' "$1"
  fi
}

warn() {
  if declare -F ui_warn >/dev/null 2>&1; then
    ui_warn "setup-sddm" "$1"
  else
    printf '[setup-sddm] warning: %s\n' "$1" >&2
  fi
}

fail() {
  if declare -F ui_error >/dev/null 2>&1; then
    ui_error "setup-sddm" "$1"
  else
    printf '[setup-sddm] error: %s\n' "$1" >&2
  fi
  exit 1
}

require_sudo() {
  if ! command -v sudo >/dev/null 2>&1; then
    fail "sudo is required to install the SDDM login screen theme."
  fi
}

detect_sddm() {
  if [[ ! -d /usr/share/sddm/themes ]]; then
    warn "SDDM theme directory was not found. Skipping login screen theming."
    exit 0
  fi
}

save_previous_theme() {
  mkdir -p "$HOME/.cache/keskos"
  local current_theme=""

  current_theme="$(grep -Rhs '^Current=' /etc/sddm.conf /etc/sddm.conf.d/*.conf 2>/dev/null | tail -n 1 | cut -d= -f2- || true)"

  if [[ -n "$current_theme" ]]; then
    printf '%s\n' "$current_theme" >"$HOME/.cache/keskos/sddm-previous-theme"
  fi
}

install_theme_files() {
  local theme_root="/usr/share/sddm/themes/keskos"

  sudo rm -rf "$theme_root"
  sudo mkdir -p "$theme_root/assets"

  sudo install -m 644 \
    "$REPO_DIR/configs/sddm/keskos/Main.qml" \
    "$theme_root/Main.qml"

  sudo install -m 644 \
    "$REPO_DIR/configs/sddm/keskos/metadata.desktop" \
    "$theme_root/metadata.desktop"

  sudo install -m 644 \
    "$REPO_DIR/configs/sddm/keskos/theme.conf" \
    "$theme_root/theme.conf"

  sudo install -m 644 \
    "$REPO_DIR/configs/sddm/keskos/assets/background.png" \
    "$theme_root/assets/background.png"

  sudo install -m 644 \
    "$REPO_DIR/configs/sddm/keskos/assets/logo.png" \
    "$theme_root/assets/logo.png"
}

apply_sddm_config() {
  local conf_file="/etc/sddm.conf.d/keskos.conf"
  local temp_file

  temp_file="$(mktemp)"

  cat >"$temp_file" <<'EOF'
[Theme]
Current=keskos
EOF

  sudo mkdir -p /etc/sddm.conf.d
  sudo install -m 644 "$temp_file" "$conf_file"
  rm -f "$temp_file"
}

main() {
  require_sudo
  detect_sddm
  save_previous_theme
  install_theme_files
  apply_sddm_config

  log "Installed the KeskOS SDDM login screen theme."
  warn "Log out or reboot to test the login screen. The previous theme, when detected, was saved to ~/.cache/keskos/sddm-previous-theme."
}

main "$@"
