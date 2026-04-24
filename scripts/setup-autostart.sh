#!/usr/bin/env bash
set -euo pipefail

log() {
  printf '[setup-autostart] %s\n' "$1"
}

mkdir -p "$HOME/.config/autostart" "$HOME/.local/bin"

rm -f "$HOME/.config/autostart/keskos-picom.desktop"
rm -f "$HOME/.config/autostart/keskos-conky.desktop"
rm -f "$HOME/.local/bin/keskos-picom-start"
rm -f "$HOME/.local/bin/keskos-start-conky"
rm -f "$HOME/.local/bin/keskos-conky-block"
rm -f "$HOME/.local/bin/keskos-select-resolution-profile"

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

cat >"$HOME/.config/autostart/keskos-eww.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Version=1.0
Name=KESKOS Eww HUD
Comment=Start the KESKOS Eww HUD
Exec=sh -lc ~/.local/bin/keskos-start-eww
OnlyShowIn=KDE;
StartupNotify=false
Terminal=false
X-KDE-autostart-after=plasmashell
EOF

log "Installed wallpaper and Eww autostart entries."
