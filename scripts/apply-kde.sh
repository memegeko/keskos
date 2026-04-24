#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${1:?usage: apply-kde.sh /path/to/repo}"

log() {
  printf '[apply-kde] %s\n' "$1"
}

warn() {
  printf '[apply-kde] warning: %s\n' "$1" >&2
}

backup_file() {
  local file_path="$1"

  if [[ -f "$file_path" && ! -f "${file_path}.keskos.bak" ]]; then
    cp "$file_path" "${file_path}.keskos.bak"
  fi
}

mkdir -p "$HOME/.local/share/color-schemes"

install -m 644 \
  "$REPO_DIR/configs/kde/keskos.colors" \
  "$HOME/.local/share/color-schemes/KESKOS.colors"

kwriteconfig_bin=""
if command -v kwriteconfig6 >/dev/null 2>&1; then
  kwriteconfig_bin="kwriteconfig6"
elif command -v kwriteconfig5 >/dev/null 2>&1; then
  kwriteconfig_bin="kwriteconfig5"
fi

kreadconfig_bin=""
if command -v kreadconfig6 >/dev/null 2>&1; then
  kreadconfig_bin="kreadconfig6"
elif command -v kreadconfig5 >/dev/null 2>&1; then
  kreadconfig_bin="kreadconfig5"
fi

apply_fallback_breeze() {
  if [[ -n "$kwriteconfig_bin" ]]; then
    "$kwriteconfig_bin" --file "$HOME/.config/kdeglobals" --group General --key ColorScheme "BreezeDark" || true
  fi

  if command -v plasma-apply-colorscheme >/dev/null 2>&1; then
    plasma-apply-colorscheme BreezeDark >/dev/null 2>&1 || true
  fi
}

apply_colors() {
  local configured_scheme=""

  if [[ -n "$kwriteconfig_bin" ]]; then
    # Writing kdeglobals directly gives Plasma a durable scheme selection even if
    # the helper tool exits successfully without persisting the setting.
    "$kwriteconfig_bin" \
      --file "$HOME/.config/kdeglobals" \
      --group General \
      --key ColorScheme \
      "KESKOS"
  fi

  if command -v plasma-apply-colorscheme >/dev/null 2>&1; then
    plasma-apply-colorscheme KESKOS >/dev/null 2>&1 || true
  fi

  if [[ -n "$kreadconfig_bin" ]]; then
    configured_scheme="$("$kreadconfig_bin" --file "$HOME/.config/kdeglobals" --group General --key ColorScheme 2>/dev/null || true)"
    [[ "$configured_scheme" == "KESKOS" ]]
    return
  fi

  [[ -n "$kwriteconfig_bin" ]]
}

apply_fonts() {
  if [[ -z "$kwriteconfig_bin" ]]; then
    warn "kwriteconfig was not found. Skipping KDE font changes."
    return
  fi

  "$kwriteconfig_bin" --file "$HOME/.config/kdeglobals" --group General --key font "JetBrainsMono Nerd Font,10,-1,5,50,0,0,0,0,0"
  "$kwriteconfig_bin" --file "$HOME/.config/kdeglobals" --group General --key fixed "JetBrainsMono Nerd Font,10,-1,5,50,0,0,0,0,0"
  "$kwriteconfig_bin" --file "$HOME/.config/kdeglobals" --group General --key smallestReadableFont "JetBrainsMono Nerd Font,8,-1,5,50,0,0,0,0,0"
  "$kwriteconfig_bin" --file "$HOME/.config/kdeglobals" --group General --key menuFont "JetBrainsMono Nerd Font,10,-1,5,50,0,0,0,0,0"
  "$kwriteconfig_bin" --file "$HOME/.config/kdeglobals" --group General --key toolBarFont "JetBrainsMono Nerd Font,10,-1,5,50,0,0,0,0,0"
}

set_black_root() {
  local script

  script='var allDesktops = desktops();
for (var i = 0; i < allDesktops.length; i++) {
  var desktop = allDesktops[i];
  desktop.wallpaperPlugin = "org.kde.image";
  desktop.currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
  desktop.writeConfig("Color", "#000000");
  desktop.writeConfig("FillMode", 2);
}'

  if command -v qdbus6 >/dev/null 2>&1; then
    qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$script" >/dev/null 2>&1 || true
    return
  fi

  if command -v qdbus >/dev/null 2>&1; then
    qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$script" >/dev/null 2>&1 || true
  fi
}

set_panel_autohide() {
  local script

  # Best-effort Plasma panel scripting. If this fails, the README documents the
  # safe manual path instead of deleting or rebuilding panels.
  script='for (var i = 0; i < panelIds.length; i++) {
  try {
    var panel = panelById(panelIds[i]);
    if (panel) {
      panel.hiding = "autohide";
    }
  } catch (error) {
  }
}'

  if command -v qdbus6 >/dev/null 2>&1; then
    qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$script" >/dev/null 2>&1 && return 0
  fi

  if command -v qdbus >/dev/null 2>&1; then
    qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$script" >/dev/null 2>&1 && return 0
  fi

  return 1
}

main() {
  backup_file "$HOME/.config/kdeglobals"
  backup_file "$HOME/.config/kwinrc"
  backup_file "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"

  if ! apply_colors; then
    warn "Failed to apply the KESKOS color scheme automatically. Falling back to Breeze Dark."
    apply_fallback_breeze
  fi

  apply_fonts
  set_black_root

  if ! set_panel_autohide; then
    warn "Unable to switch panels to auto-hide automatically. Use the manual panel steps from the README if needed."
  fi

  if command -v qdbus6 >/dev/null 2>&1; then
    qdbus6 org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true
  elif command -v qdbus >/dev/null 2>&1; then
    qdbus org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true
  fi

  log "Installed and applied KDE theme settings."
}

main "$@"
