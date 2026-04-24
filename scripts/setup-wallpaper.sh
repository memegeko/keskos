#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${1:?usage: setup-wallpaper.sh /path/to/repo}"

log() {
  printf '[setup-wallpaper] %s\n' "$1"
}

warn() {
  printf '[setup-wallpaper] warning: %s\n' "$1" >&2
}

mkdir -p "$HOME/.local/share/keskos/assets" "$HOME/.local/bin"

installed_wallpaper=0

for wallpaper_asset in \
  "$REPO_DIR/assets/wallpaper.svg" \
  "$REPO_DIR/assets/wallpaper-1920x1080.png" \
  "$REPO_DIR/assets/wallpaper-2560x1440.png" \
  "$REPO_DIR/assets/wallpaper-4096x2160.png" \
  "$REPO_DIR/assets/wallpaper.png" \
  "$REPO_DIR/assets/wallpaper.jpg" \
  "$REPO_DIR/assets/wallpaper.jpeg"; do
  if [[ -f "$wallpaper_asset" ]]; then
    install -m 644 \
      "$wallpaper_asset" \
      "$HOME/.local/share/keskos/assets/$(basename "$wallpaper_asset")"
    installed_wallpaper=1
  fi
done

if [[ "$installed_wallpaper" -eq 0 ]]; then
  warn "No wallpaper asset was found in the repo."
  exit 1
fi

cat >"$HOME/.local/bin/keskos-wallpaper-apply" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

detect_screen_width() {
  local width=""

  if command -v kscreen-doctor >/dev/null 2>&1; then
    width="$(
      kscreen-doctor -o 2>/dev/null | awk '
        /enabled/ && match($0, /([0-9]+)x([0-9]+)/, found) {
          print found[1];
          exit;
        }
      ' || true
    )"
  fi

  if [[ -z "$width" ]] && command -v xrandr >/dev/null 2>&1; then
    width="$(
      xrandr --current 2>/dev/null | awk '
        / connected primary / {
          for (i = 1; i <= NF; i++) {
            if ($i ~ /^[0-9]+x[0-9]+\+[0-9]+\+[0-9]+$/) {
              split($i, parts, /x|\+/);
              print parts[1];
              exit;
            }
          }
        }
        / connected / {
          for (i = 1; i <= NF; i++) {
            if ($i ~ /^[0-9]+x[0-9]+\+[0-9]+\+[0-9]+$/) {
              split($i, parts, /x|\+/);
              print parts[1];
              exit;
            }
          }
        }
        match($0, /current[[:space:]]+([0-9]+)/, found) {
          print found[1];
          exit;
        }
      ' || true
    )"
  fi

  if [[ -z "$width" || ! "$width" =~ ^[0-9]+$ ]]; then
    width="1920"
  fi

  printf '%s\n' "$width"
}

select_wallpaper() {
  local width="$1"
  local asset_dir="${HOME}/.local/share/keskos/assets"

  if (( width >= 3840 )) && [[ -f "${asset_dir}/wallpaper-4096x2160.png" ]]; then
    printf '%s\n' "${asset_dir}/wallpaper-4096x2160.png"
    return 0
  fi

  if (( width >= 2560 )) && [[ -f "${asset_dir}/wallpaper-2560x1440.png" ]]; then
    printf '%s\n' "${asset_dir}/wallpaper-2560x1440.png"
    return 0
  fi

  if [[ -f "${asset_dir}/wallpaper-1920x1080.png" ]]; then
    printf '%s\n' "${asset_dir}/wallpaper-1920x1080.png"
    return 0
  fi

  for candidate in \
    "${asset_dir}/wallpaper.svg" \
    "${asset_dir}/wallpaper.png" \
    "${asset_dir}/wallpaper.jpg" \
    "${asset_dir}/wallpaper.jpeg"; do
    if [[ -f "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  return 1
}

set_black_fallback() {
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

apply_with_qdbus() {
  local qdbus_bin="$1"
  local wallpaper="$2"
  local escaped_path
  local script

  escaped_path="${wallpaper//\\/\\\\}"
  escaped_path="${escaped_path//\"/\\\"}"

  script='var allDesktops = desktops();
for (var i = 0; i < allDesktops.length; i++) {
  var desktop = allDesktops[i];
  desktop.wallpaperPlugin = "org.kde.image";
  desktop.currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
  desktop.writeConfig("Image", "file://'"${escaped_path}"'");
  desktop.writeConfig("FillMode", 2);
  desktop.writeConfig("Blur", false);
  desktop.writeConfig("Color", "#000000");
}'

  "$qdbus_bin" org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$script"
}

main() {
  local width wallpaper applied=1

  width="$(detect_screen_width)"

  if ! wallpaper="$(select_wallpaper "$width")"; then
    printf 'keskos-wallpaper-apply: no installed wallpaper asset was found\n' >&2
    exit 1
  fi

  set_black_fallback

  if command -v plasma-apply-wallpaperimage >/dev/null 2>&1; then
    plasma-apply-wallpaperimage "$wallpaper" >/dev/null 2>&1 && applied=0
  fi

  if command -v qdbus6 >/dev/null 2>&1; then
    apply_with_qdbus qdbus6 "$wallpaper" >/dev/null 2>&1 && exit 0
  fi

  if command -v qdbus >/dev/null 2>&1; then
    apply_with_qdbus qdbus "$wallpaper" >/dev/null 2>&1 && exit 0
  fi

  if [[ "$applied" -eq 0 ]]; then
    exit 0
  fi

  set_black_fallback
  printf 'keskos-wallpaper-apply: Plasma wallpaper tools were unavailable, keeping the black fallback\n' >&2
  exit 0
}

main "$@"
EOF

chmod +x "$HOME/.local/bin/keskos-wallpaper-apply"

if ! "$HOME/.local/bin/keskos-wallpaper-apply"; then
  warn "Automatic wallpaper application failed. The wallpaper is still installed for manual selection."
fi

log "Installed wallpaper assets and the apply helper."
