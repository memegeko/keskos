#!/usr/bin/env bash
set -euo pipefail

SCRIPT_SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_SOURCE_DIR/lib-ui.sh" ]]; then
  # shellcheck source=scripts/lib-ui.sh
  . "$SCRIPT_SOURCE_DIR/lib-ui.sh"
fi

REPO_DIR="${1:?usage: setup-lockscreen.sh /path/to/repo}"

log() {
  if declare -F ui_log >/dev/null 2>&1; then
    ui_log "setup-lockscreen" "$1"
  else
    printf '[setup-lockscreen] %s\n' "$1"
  fi
}

warn() {
  if declare -F ui_warn >/dev/null 2>&1; then
    ui_warn "setup-lockscreen" "$1"
  else
    printf '[setup-lockscreen] warning: %s\n' "$1" >&2
  fi
}

backup_file() {
  local file_path="$1"

  if [[ -f "$file_path" && ! -f "${file_path}.keskos.bak" ]]; then
    cp "$file_path" "${file_path}.keskos.bak"
  fi
}

backup_dir_once() {
  local dir_path="$1"

  if [[ -d "$dir_path" && ! -d "${dir_path}.keskos.bak" ]]; then
    cp -a "$dir_path" "${dir_path}.keskos.bak"
  fi
}

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

save_previous_ksplash() {
  local current_theme=""

  mkdir -p "$HOME/.cache/keskos"

  if [[ -n "$kreadconfig_bin" ]]; then
    current_theme="$("$kreadconfig_bin" --file "$HOME/.config/ksplashrc" --group KSplash --key Theme 2>/dev/null || true)"
  fi

  if [[ -n "$current_theme" ]]; then
    printf '%s\n' "$current_theme" >"$HOME/.cache/keskos/previous-ksplash-theme"
  fi
}

install_splash_package() {
  local theme_root="$HOME/.local/share/plasma/look-and-feel/com.keskos.desktop"

  mkdir -p "$theme_root/contents/splash/assets"

  install -m 644 \
    "$REPO_DIR/configs/look-and-feel/com.keskos.desktop/metadata.json" \
    "$theme_root/metadata.json"

  install -m 644 \
    "$REPO_DIR/configs/look-and-feel/com.keskos.desktop/contents/splash/Splash.qml" \
    "$theme_root/contents/splash/Splash.qml"

  install -m 644 \
    "$REPO_DIR/configs/look-and-feel/com.keskos.desktop/contents/splash/assets/logo.png" \
    "$theme_root/contents/splash/assets/logo.png"

  install -m 644 \
    "$REPO_DIR/configs/look-and-feel/com.keskos.desktop/contents/splash/assets/spinner.png" \
    "$theme_root/contents/splash/assets/spinner.png"
}

install_lockscreen_shell_override() {
  local shell_id="org.kde.plasma.desktop"
  local system_shell_root="/usr/share/plasma/shells/$shell_id"
  local user_shell_root="$HOME/.local/share/plasma/shells/$shell_id"

  if [[ ! -d "$system_shell_root" ]]; then
    warn "The stock Plasma desktop shell package was not found. Skipping lock screen override."
    return 1
  fi

  mkdir -p "$HOME/.local/share/plasma/shells"
  backup_dir_once "$user_shell_root"
  rm -rf "$user_shell_root"
  cp -a "$system_shell_root" "$user_shell_root"

  mkdir -p "$user_shell_root/contents/lockscreen/assets"

  install -m 644 \
    "$REPO_DIR/configs/look-and-feel/com.keskos.desktop/contents/lockscreen/LockScreen.qml" \
    "$user_shell_root/contents/lockscreen/LockScreen.qml"

  install -m 644 \
    "$REPO_DIR/configs/look-and-feel/com.keskos.desktop/contents/lockscreen/assets/background.png" \
    "$user_shell_root/contents/lockscreen/assets/background.png"

  install -m 644 \
    "$REPO_DIR/configs/look-and-feel/com.keskos.desktop/contents/lockscreen/assets/logo.png" \
    "$user_shell_root/contents/lockscreen/assets/logo.png"
}

apply_config() {
  local background_path="$HOME/.local/share/plasma/shells/org.kde.plasma.desktop/contents/lockscreen/assets/background.png"

  if [[ -z "$kwriteconfig_bin" ]]; then
    warn "kwriteconfig was not found. The lock screen files were installed, but Plasma was not pointed at the matching splash settings automatically."
    return
  fi

  backup_file "$HOME/.config/kscreenlockerrc"
  backup_file "$HOME/.config/ksplashrc"
  save_previous_ksplash

  "$kwriteconfig_bin" --file "$HOME/.config/kscreenlockerrc" --group Greeter --key WallpaperPlugin "org.kde.image"
  "$kwriteconfig_bin" --file "$HOME/.config/kscreenlockerrc" --group Greeter --group Wallpaper --group org.kde.image --group General --key Image "file://$background_path"
  "$kwriteconfig_bin" --file "$HOME/.config/kscreenlockerrc" --group Greeter --group Wallpaper --group org.kde.image --group General --key FillMode "2"
  "$kwriteconfig_bin" --file "$HOME/.config/ksplashrc" --group KSplash --key Engine "KSplashQML"
  "$kwriteconfig_bin" --file "$HOME/.config/ksplashrc" --group KSplash --key Theme "com.keskos.desktop"
}

main() {
  install_splash_package
  install_lockscreen_shell_override || true
  apply_config

  log "Installed the matching KeskOS Plasma lock screen and splash theme."
  warn "Lock the session or reboot to test it. A previous local shell override was backed up to ~/.local/share/plasma/shells/org.kde.plasma.desktop.keskos.bak when present."
}

main "$@"
