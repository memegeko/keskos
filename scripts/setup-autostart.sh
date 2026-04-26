#!/usr/bin/env bash
set -euo pipefail

SCRIPT_SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_SOURCE_DIR/lib-ui.sh" ]]; then
  # shellcheck source=scripts/lib-ui.sh
  . "$SCRIPT_SOURCE_DIR/lib-ui.sh"
fi

REPO_DIR="${1:-}"
WIDGETS_ENABLED="${2:-n}"

log() {
  if declare -F ui_log >/dev/null 2>&1; then
    ui_log "setup-autostart" "$1"
  else
    printf '[setup-autostart] %s\n' "$1"
  fi
}

mkdir -p "$HOME/.config/autostart" "$HOME/.local/bin"

rm -f "$HOME/.config/autostart/keskos-picom.desktop"
rm -f "$HOME/.config/autostart/keskos-conky.desktop"
rm -f "$HOME/.config/autostart/keskos-eww.desktop"
rm -f "$HOME/.config/autostart/keskos-quickshell.desktop"
rm -f "$HOME/.local/bin/keskos-picom-start"
rm -f "$HOME/.local/bin/keskos-start-conky"
rm -f "$HOME/.local/bin/keskos-conky-block"
rm -f "$HOME/.local/bin/keskos-start-eww"
rm -f "$HOME/.local/bin/keskos-eww-data"

cat >"$HOME/.config/autostart/keskos-wallpaper.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Version=1.0
Name=KESKOS Wallpaper
Comment=Re-apply the KESKOS wallpaper on login
Exec=sh -lc ~/.local/bin/keskos-wallpaper-apply
OnlyShowIn=KDE;
StartupNotify=false
Terminal=false
X-KDE-autostart-after=plasmashell
EOF

if [[ "$WIDGETS_ENABLED" == "y" ]]; then
  cat >"$HOME/.config/autostart/keskos-quickshell.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Version=1.0
Name=KESKOS Quickshell HUD
Comment=Start the KESKOS Quickshell HUD
Exec=sh -lc ~/.local/bin/keskos-start-quickshell
OnlyShowIn=KDE;
StartupNotify=false
Terminal=false
X-KDE-autostart-after=plasmashell
EOF

  log "Installed wallpaper and Quickshell autostart entries."
else
  rm -f "$HOME/.config/autostart/keskos-quickshell.desktop"
  log "Installed wallpaper autostart and skipped HUD autostart."
fi
