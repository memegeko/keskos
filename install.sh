#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UI_LIB="${SCRIPT_DIR}/scripts/lib-ui.sh"
INSTALL_WIDGETS_ANSWER="${KESKOS_INSTALL_WIDGETS:-}"
INSTALL_LIBREWOLF_ANSWER="${KESKOS_INSTALL_LIBREWOLF:-}"
APPLY_BRANDING_ANSWER="${KESKOS_APPLY_BRANDING:-}"
APPLY_SDDM_ANSWER="${KESKOS_APPLY_SDDM:-}"
PROCEED_INSTALL_ANSWER=""
STEP_INDEX=0
TOTAL_STEPS=14

if [[ -f "$UI_LIB" ]]; then
  # shellcheck source=scripts/lib-ui.sh
  . "$UI_LIB"
fi

log() {
  if declare -F ui_log >/dev/null 2>&1; then
    ui_log "keskos" "$1"
  else
    printf '[keskos] %s\n' "$1"
  fi
}

info() {
  if declare -F ui_info >/dev/null 2>&1; then
    ui_info "keskos" "$1"
  else
    printf '[keskos] %s\n' "$1"
  fi
}

warn() {
  if declare -F ui_warn >/dev/null 2>&1; then
    ui_warn "keskos" "$1"
  else
    printf '[keskos] warning: %s\n' "$1" >&2
  fi
}

fail() {
  if declare -F ui_error >/dev/null 2>&1; then
    ui_error "keskos" "$1"
  else
    printf '[keskos] error: %s\n' "$1" >&2
  fi
  exit 1
}

feature_answers_are_preseeded() {
  [[ -n "$INSTALL_WIDGETS_ANSWER" ]] \
    && [[ -n "$INSTALL_LIBREWOLF_ANSWER" ]] \
    && [[ -n "$APPLY_BRANDING_ANSWER" ]] \
    && [[ -n "$APPLY_SDDM_ANSWER" ]]
}

should_skip_final_confirmation() {
  [[ ! -t 0 ]] || feature_answers_are_preseeded
}

bool_display() {
  local value="$1"
  if declare -F _ui_yes_no_display >/dev/null 2>&1; then
    _ui_yes_no_display "$value"
  else
    if [[ "${value,,}" == "y" ]]; then
      printf 'Enabled'
    else
      printf 'Disabled'
    fi
  fi
}

next_step() {
  local title="$1"
  STEP_INDEX=$((STEP_INDEX + 1))
  if declare -F ui_step >/dev/null 2>&1; then
    ui_step "$STEP_INDEX" "$TOTAL_STEPS" "$title"
  else
    printf '\n[%02d/%02d] %s\n' "$STEP_INDEX" "$TOTAL_STEPS" "$title"
  fi
}

run_step() {
  local title="$1"
  shift
  next_step "$title"
  "$@"
}

skip_step() {
  local title="$1"
  local message="$2"
  next_step "$title"
  info "$message"
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
  if declare -F ui_prompt_yes_no >/dev/null 2>&1; then
    ui_prompt_yes_no \
      INSTALL_WIDGETS_ANSWER \
      "n" \
      "Install KeskOS HUD widgets?" \
      "Adds the optional Quickshell HUD on Plasma Wayland."
  else
    echo "Install KeskOS HUD widgets? (y/n)"
    read -r INSTALL_WIDGETS_ANSWER
  fi
}

prompt_librewolf_install() {
  if declare -F ui_prompt_yes_no >/dev/null 2>&1; then
    ui_prompt_yes_no \
      INSTALL_LIBREWOLF_ANSWER \
      "n" \
      "Install the Kesk OS themed LibreWolf browser?" \
      "Adds the offline homepage and browser chrome theme without touching your other app choices."
  else
    printf 'Do you want to install the Kesk OS themed LibreWolf browser? [y/N]\n'
    read -r INSTALL_LIBREWOLF_ANSWER
  fi
}

prompt_system_branding() {
  if declare -F ui_prompt_yes_no >/dev/null 2>&1; then
    ui_prompt_yes_no \
      APPLY_BRANDING_ANSWER \
      "n" \
      "Apply optional system branding so apps report Kesk OS?" \
      "Changes the user-facing distro name while keeping Arch compatibility identifiers."
  else
    printf 'Apply optional system branding so apps report Kesk OS? [y/N]\n'
    read -r APPLY_BRANDING_ANSWER
  fi
}

prompt_sddm_theme() {
  if declare -F ui_prompt_yes_no >/dev/null 2>&1; then
    ui_prompt_yes_no \
      APPLY_SDDM_ANSWER \
      "n" \
      "Apply the optional KeskOS SDDM login and lock theme?" \
      "Installs the matching login screen, lock screen, and splash styling."
  else
    printf 'Apply optional KeskOS login screen theme for SDDM? [y/N]\n'
    read -r APPLY_SDDM_ANSWER
  fi
}

prompt_final_confirmation() {
  if should_skip_final_confirmation; then
    info "Skipping final confirmation because answers were preseeded or the session is non-interactive."
    PROCEED_INSTALL_ANSWER="y"
    return
  fi

  if declare -F ui_prompt_yes_no >/dev/null 2>&1; then
    ui_prompt_yes_no \
      PROCEED_INSTALL_ANSWER \
      "y" \
      "Proceed with KeskOS installation?" \
      "This will install packages, apply themes, and write the selected user and system configuration."
  else
    printf 'Proceed with KeskOS installation? [Y/n]\n'
    read -r PROCEED_INSTALL_ANSWER
  fi

  if [[ "${PROCEED_INSTALL_ANSWER,,}" != "y" ]]; then
    warn "Installation cancelled before changes were applied."
    exit 0
  fi
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

show_intro() {
  if declare -F ui_banner >/dev/null 2>&1; then
    ui_banner
  fi
  info "This installer applies the KeskOS launcher, wallpaper, terminal profile, KDE theme, and selected optional layers."
  info "Test in a VM first if you can. Theme and panel behavior are recoverable, but it is still safer to validate there."
  info "KDE panels and themes are changed intentionally, not silently destroyed, unless you have explicitly chosen a panel-removal path elsewhere."
}

show_preflight() {
  if declare -F ui_section >/dev/null 2>&1; then
    ui_section "Preflight"
  fi

  if [[ ${EUID} -eq 0 ]]; then
    fail "Do not run install.sh as root. Run it as your normal user; sudo is used only for pacman."
  fi

  require_arch

  if declare -F ui_summary_row >/dev/null 2>&1; then
    ui_summary_row "User" "$USER"
    ui_summary_row "Session" "${XDG_SESSION_TYPE:-unknown}"
    ui_summary_row "Desktop" "${XDG_CURRENT_DESKTOP:-KDE Plasma}"
    ui_summary_row "Repo" "$SCRIPT_DIR"
  fi
}

show_feature_selection() {
  if declare -F ui_section >/dev/null 2>&1; then
    ui_section "Feature Selection"
  fi

  prompt_widget_install
  prompt_librewolf_install
  prompt_system_branding
  prompt_sddm_theme
}

show_selection_summary() {
  if declare -F ui_section >/dev/null 2>&1; then
    ui_section "Selection Summary"
  fi

  if declare -F ui_summary_row >/dev/null 2>&1; then
    ui_summary_row "Widgets" "$(bool_display "$INSTALL_WIDGETS_ANSWER")"
    ui_summary_row "LibreWolf" "$(bool_display "$INSTALL_LIBREWOLF_ANSWER")"
    ui_summary_row "Branding" "$(bool_display "$APPLY_BRANDING_ANSWER")"
    ui_summary_row "Login/Lock Theme" "$(bool_display "$APPLY_SDDM_ANSWER")"
  else
    info "Widgets: $(bool_display "$INSTALL_WIDGETS_ANSWER")"
    info "LibreWolf: $(bool_display "$INSTALL_LIBREWOLF_ANSWER")"
    info "Branding: $(bool_display "$APPLY_BRANDING_ANSWER")"
    info "Login/Lock Theme: $(bool_display "$APPLY_SDDM_ANSWER")"
  fi
}

show_completion() {
  if declare -F ui_section >/dev/null 2>&1; then
    ui_section "Complete"
  fi

  if declare -F ui_success >/dev/null 2>&1; then
    ui_success "keskos" "KESKOS setup complete."
  else
    printf '\nKESKOS setup complete.\n'
  fi

  if declare -F ui_summary_row >/dev/null 2>&1; then
    ui_summary_row "Widgets" "$(bool_display "$INSTALL_WIDGETS_ANSWER")"
    ui_summary_row "LibreWolf" "$(bool_display "$INSTALL_LIBREWOLF_ANSWER")"
    ui_summary_row "Login/Lock Theme" "$(bool_display "$APPLY_SDDM_ANSWER")"
  fi

  info "Next: Log out and back in."
  info "Then press Meta or Meta+K to open the launcher."
  info "If something looks wrong, rerun: scripts/setup-rofi.sh, scripts/setup-sddm.sh, or scripts/setup-lockscreen.sh"
}

main() {
  show_intro
  show_preflight
  show_feature_selection
  show_selection_summary
  prompt_final_confirmation

  if declare -F ui_section >/dev/null 2>&1; then
    ui_section "Installing"
  fi

  run_step "Creating user-local directories" prepare_directories
  run_step "Installing base packages" install_base_packages
  run_step "Installing optional window-control helpers" bash "$SCRIPT_DIR/scripts/setup-window-tools.sh" "$SCRIPT_DIR"
  run_step "Installing rofi launcher assets" bash "$SCRIPT_DIR/scripts/setup-rofi.sh" "$SCRIPT_DIR"
  run_step "Installing terminal profile assets" bash "$SCRIPT_DIR/scripts/setup-terminal.sh" "$SCRIPT_DIR"
  run_step "Installing wallpaper assets" bash "$SCRIPT_DIR/scripts/setup-wallpaper.sh" "$SCRIPT_DIR"

  if [[ "$INSTALL_WIDGETS_ANSWER" == "y" ]]; then
    run_step "Installing the optional Quickshell HUD" bash "$SCRIPT_DIR/scripts/setup-quickshell.sh" "$SCRIPT_DIR"
  else
    skip_step "Installing the optional Quickshell HUD" "Skipping widget installation and keeping minimal mode."
  fi

  if [[ "$INSTALL_LIBREWOLF_ANSWER" == "y" ]]; then
    next_step "Installing the optional Kesk OS LibreWolf browser layer"
    if ! bash "$SCRIPT_DIR/scripts/setup-librewolf.sh" "$SCRIPT_DIR"; then
      warn "LibreWolf setup did not complete cleanly. Continuing with the rest of the install."
    fi
  else
    skip_step "Installing the optional Kesk OS LibreWolf browser layer" "Skipping LibreWolf installation and theming."
  fi

  if [[ "$APPLY_BRANDING_ANSWER" == "y" ]]; then
    run_step "Applying optional Kesk OS system branding" bash "$SCRIPT_DIR/scripts/setup-branding.sh"
  else
    skip_step "Applying optional Kesk OS system branding" "Skipping optional system branding and keeping the base Arch identity."
  fi

  if [[ "$APPLY_SDDM_ANSWER" == "y" ]]; then
    next_step "Applying optional login, lock, and splash themes"
    bash "$SCRIPT_DIR/scripts/setup-sddm.sh" "$SCRIPT_DIR"
    bash "$SCRIPT_DIR/scripts/setup-lockscreen.sh" "$SCRIPT_DIR"
  else
    skip_step "Applying optional login, lock, and splash themes" "Skipping optional SDDM and lock-screen theming."
  fi

  run_step "Installing autostart entries" bash "$SCRIPT_DIR/scripts/setup-autostart.sh" "$SCRIPT_DIR" "$INSTALL_WIDGETS_ANSWER"
  run_step "Installing launcher shortcuts" bash "$SCRIPT_DIR/scripts/setup-shortcuts.sh" "$SCRIPT_DIR"
  run_step "Applying KDE theme settings" bash "$SCRIPT_DIR/scripts/apply-kde.sh" "$SCRIPT_DIR"

  next_step "Restarting Plasma and starting optional services"
  restart_plasma
  stop_old_widget_processes
  start_quickshell_hud

  show_completion
}

main "$@"
