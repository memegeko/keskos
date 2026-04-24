#!/usr/bin/env bash
set -euo pipefail

log() {
  printf '[setup-autostart] %s\n' "$1"
}

mkdir -p "$HOME/.config/autostart" "$HOME/.local/bin"

cat >"$HOME/.local/bin/keskos-picom-start" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

if ! command -v picom >/dev/null 2>&1; then
  exit 0
fi

if [[ "${XDG_SESSION_TYPE:-}" == "wayland" ]]; then
  exit 0
fi

# Plasma already has KWin compositing. Running picom on top of that is a common
# source of ghosting, duplicate window trails, and lag, especially in VMs.
if [[ "${KESKOS_FORCE_PICOM:-0}" != "1" ]]; then
  if [[ "${KDE_FULL_SESSION:-}" == "true" || "${XDG_CURRENT_DESKTOP:-}" == *KDE* || "${XDG_CURRENT_DESKTOP:-}" == *Plasma* ]]; then
    exit 0
  fi

  if command -v systemd-detect-virt >/dev/null 2>&1 && systemd-detect-virt --quiet; then
    exit 0
  fi
fi

pgrep -x picom >/dev/null 2>&1 && exit 0
exec picom --config "$HOME/.config/picom/picom.conf"
EOF

chmod +x "$HOME/.local/bin/keskos-picom-start"

cat >"$HOME/.config/autostart/keskos-picom.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Version=1.0
Name=KESKOS Picom
Comment=Start the KESKOS picom compositor
Exec=sh -lc ~/.local/bin/keskos-picom-start
OnlyShowIn=KDE;
StartupNotify=false
Terminal=false
X-KDE-autostart-after=panel
EOF

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

cat >"$HOME/.config/autostart/keskos-conky.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Version=1.0
Name=KESKOS HUD
Comment=Start the KESKOS Conky HUD
Exec=sh -lc ~/.local/bin/keskos-start-conky
OnlyShowIn=KDE;
StartupNotify=false
Terminal=false
X-KDE-autostart-after=plasmashell
EOF

log "Installed picom, wallpaper, and Conky autostart entries."
