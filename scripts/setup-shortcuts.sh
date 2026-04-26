#!/usr/bin/env bash
set -euo pipefail

SCRIPT_SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_SOURCE_DIR/lib-ui.sh" ]]; then
  # shellcheck source=scripts/lib-ui.sh
  . "$SCRIPT_SOURCE_DIR/lib-ui.sh"
fi

REPO_DIR="${1:?usage: setup-shortcuts.sh /path/to/repo}"

log() {
  if declare -F ui_log >/dev/null 2>&1; then
    ui_log "setup-shortcuts" "$1"
  else
    printf '[setup-shortcuts] %s\n' "$1"
  fi
}

warn() {
  if declare -F ui_warn >/dev/null 2>&1; then
    ui_warn "setup-shortcuts" "$1"
  else
    printf '[setup-shortcuts] warning: %s\n' "$1" >&2
  fi
}

fail() {
  if declare -F ui_error >/dev/null 2>&1; then
    ui_error "setup-shortcuts" "$1"
  else
    printf '[setup-shortcuts] error: %s\n' "$1" >&2
  fi
  exit 1
}

kwriteconfig_bin=""
if command -v kwriteconfig6 >/dev/null 2>&1; then
  kwriteconfig_bin="kwriteconfig6"
elif command -v kwriteconfig5 >/dev/null 2>&1; then
  kwriteconfig_bin="kwriteconfig5"
fi

qdbus_bin=""
if command -v qdbus6 >/dev/null 2>&1; then
  qdbus_bin="qdbus6"
elif command -v qdbus >/dev/null 2>&1; then
  qdbus_bin="qdbus"
fi

kbuildsycoca_bin=""
if command -v kbuildsycoca6 >/dev/null 2>&1; then
  kbuildsycoca_bin="kbuildsycoca6"
elif command -v kbuildsycoca5 >/dev/null 2>&1; then
  kbuildsycoca_bin="kbuildsycoca5"
fi

if [[ -z "$kwriteconfig_bin" ]]; then
  fail "kwriteconfig was not found. KDE shortcut tools are required."
fi

mkdir -p "$HOME/.config" "$HOME/.local/bin" "$HOME/.local/share/applications"

backup_file() {
  local file_path="$1"

  if [[ -f "$file_path" && ! -f "${file_path}.keskos.bak" ]]; then
    cp "$file_path" "${file_path}.keskos.bak"
  fi
}

cleanup_legacy_keskos_bindings() {
  # Only remove files installed by older keskos revisions.
  rm -f "$HOME/.local/bin/keskos-dispatch"
  rm -f "$HOME/.local/share/applications"/keskos-dispatch-*.desktop

  # Clear any stale modifier-only launcher binding before we re-register it.
  "$kwriteconfig_bin" \
    --file "$HOME/.config/kwinrc" \
    --group ModifierOnlyShortcuts \
    --key Meta \
    "" >/dev/null 2>&1 || true
}

normalize_plasma_workspace_launcher() {
  local launcher_value="Alt+F1,Alt+F1,Activate Application Launcher"

  "$kwriteconfig_bin" \
    --file "$HOME/.config/kglobalshortcutsrc" \
    --group plasmashell \
    --key "activate application launcher" \
    "$launcher_value" >/dev/null 2>&1 || true
}

install_launcher_desktop_files() {
  local desktop_file=""

  while IFS= read -r desktop_file; do
    install -m 644 \
      "$desktop_file" \
      "$HOME/.local/share/applications/$(basename "$desktop_file")"
  done < <(find "$REPO_DIR/desktop" -maxdepth 1 -type f -name '*.desktop' | sort)
}

write_application_shortcut() {
  local desktop_id="$1"
  local shortcut_value="$2"

  "$kwriteconfig_bin" \
    --file "$HOME/.config/kglobalshortcutsrc" \
    --group "services/$desktop_id" \
    --key "_launch" \
    "$shortcut_value"

  "$kwriteconfig_bin" \
    --file "$HOME/.config/kglobalshortcutsrc" \
    --group "$desktop_id" \
    --key "_launch" \
    "$shortcut_value"
}

clear_conflicting_shortcuts() {
  "$kwriteconfig_bin" \
    --file "$HOME/.config/kglobalshortcutsrc" \
    --group kwin \
    --key "Edit Tiles" \
    "none,none,Toggle Tiles Editor" >/dev/null 2>&1 || true

  "$kwriteconfig_bin" \
    --file "$HOME/.config/kglobalshortcutsrc" \
    --group kwin \
    --key Overview \
    "none,none,Toggle Overview" >/dev/null 2>&1 || true

  "$kwriteconfig_bin" \
    --file "$HOME/.config/kglobalshortcutsrc" \
    --group kwin \
    --key "Walk Through Windows (Reverse)" \
    "Alt+Shift+Tab,Alt+Shift+Tab,Walk Through Windows (Reverse)" >/dev/null 2>&1 || true

  write_application_shortcut "org.kde.spectacle.desktop" "Print,Print,Spectacle"
  write_application_shortcut "org.kde.kscreen.desktop" "Display,Display,Display Configuration"
}

apply_launcher_shortcuts() {
  write_application_shortcut "keskos-launcher.desktop" "Meta+K,Meta+K,KESKOS Launcher"
  write_application_shortcut "keskos-terminal.desktop" "Meta+T\\tMeta+Return,Meta+T\\tMeta+Return,KESKOS Terminal"
  write_application_shortcut "keskos-files.desktop" "Meta+N,Meta+N,KESKOS Files"
  write_application_shortcut "keskos-browser.desktop" "Meta+W,Meta+W,KESKOS Browser"
  write_application_shortcut "keskos-launcher-apps.desktop" "Meta+Shift+K,Meta+Shift+K,KESKOS Apps"
  write_application_shortcut "keskos-launcher-windows.desktop" "Meta+Shift+Tab,Meta+Shift+Tab,KESKOS Windows"
  write_application_shortcut "keskos-launcher-settings.desktop" "Meta+Shift+S,Meta+Shift+S,KESKOS Settings"
  write_application_shortcut "keskos-launcher-power.desktop" "Meta+P,Meta+P,KESKOS Power"
}

apply_modifier_only_meta() {
  local meta_action="org.kde.kglobalaccel,/component/keskos_launcher_desktop,org.kde.kglobalaccel.Component,invokeShortcut,_launch"

  "$kwriteconfig_bin" \
    --file "$HOME/.config/kwinrc" \
    --group ModifierOnlyShortcuts \
    --key Meta \
    "$meta_action" >/dev/null 2>&1 || true
}

refresh_kde_shortcuts() {
  if [[ -n "$kbuildsycoca_bin" ]]; then
    "$kbuildsycoca_bin" >/dev/null 2>&1 || true
  fi

  if [[ -n "$qdbus_bin" ]]; then
    "$qdbus_bin" org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true
  fi
}

main() {
  backup_file "$HOME/.config/kglobalshortcutsrc"
  backup_file "$HOME/.config/kwinrc"

  cleanup_legacy_keskos_bindings
  normalize_plasma_workspace_launcher
  install_launcher_desktop_files
  clear_conflicting_shortcuts
  apply_launcher_shortcuts
  apply_modifier_only_meta
  refresh_kde_shortcuts

  log "Installed all KESKOS launcher entries, bound the Meta-based shortcuts, and registered Meta as the main launcher key."
}

main "$@"
