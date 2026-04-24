#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${1:?usage: setup-shortcuts.sh /path/to/repo}"

log() {
  printf '[setup-shortcuts] %s\n' "$1"
}

warn() {
  printf '[setup-shortcuts] warning: %s\n' "$1" >&2
}

fail() {
  printf '[setup-shortcuts] error: %s\n' "$1" >&2
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

  # Clear any previous modifier-only Meta binding so the launcher stays on Meta+K.
  "$kwriteconfig_bin" \
    --file "$HOME/.config/kwinrc" \
    --group ModifierOnlyShortcuts \
    --key Meta \
    --delete >/dev/null 2>&1 || true
}

install_launcher_desktop_file() {
  install -m 644 \
    "$REPO_DIR/desktop/keskos-launcher.desktop" \
    "$HOME/.local/share/applications/keskos-launcher.desktop"
}

apply_launcher_shortcut() {
  local shortcut_value="Meta+K,Meta+K,KESKOS Launcher"

  "$kwriteconfig_bin" \
    --file "$HOME/.config/kglobalshortcutsrc" \
    --group "services/keskos-launcher.desktop" \
    --key "_launch" \
    "$shortcut_value"

  "$kwriteconfig_bin" \
    --file "$HOME/.config/kglobalshortcutsrc" \
    --group "keskos-launcher.desktop" \
    --key "_launch" \
    "$shortcut_value"
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
  install_launcher_desktop_file
  apply_launcher_shortcut
  refresh_kde_shortcuts

  log "Installed the KESKOS launcher desktop file and bound it to Meta+K."
}

main "$@"
