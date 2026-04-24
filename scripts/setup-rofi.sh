#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${1:?usage: setup-rofi.sh /path/to/repo}"

log() {
  printf '[setup-rofi] %s\n' "$1"
}

mkdir -p "$HOME/.config/rofi" "$HOME/.local/bin" "$HOME/.local/share/applications"

install -m 644 \
  "$REPO_DIR/configs/rofi/keskos.rasi" \
  "$HOME/.config/rofi/keskos.rasi"

# Build the launcher as a user-local helper so the desktop entry can stay simple.
cat >"$HOME/.local/bin/keskos-launcher" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

THEME="${HOME}/.config/rofi/keskos.rasi"
PROMPT='KESK >'

notify_or_print() {
  local message="$1"
  if command -v notify-send >/dev/null 2>&1; then
    notify-send "keskos" "$message"
  else
    printf 'keskos: %s\n' "$message" >&2
  fi
}

run_cmd() {
  if "$@"; then
    return 0
  fi

  notify_or_print "Failed to run: $*"
  return 1
}

run_if_exists() {
  local command_name="$1"
  shift

  if ! command -v "$command_name" >/dev/null 2>&1; then
    notify_or_print "Missing command: $command_name"
    return 1
  fi

  run_cmd "$command_name" "$@"
}

run_logout() {
  if command -v qdbus6 >/dev/null 2>&1; then
    qdbus6 org.kde.Shutdown /Shutdown org.kde.Shutdown.logout >/dev/null 2>&1 && return 0
    qdbus6 org.kde.ksmserver /KSMServer logout 0 0 0 >/dev/null 2>&1 && return 0
  fi

  if command -v qdbus >/dev/null 2>&1; then
    qdbus org.kde.Shutdown /Shutdown org.kde.Shutdown.logout >/dev/null 2>&1 && return 0
    qdbus org.kde.ksmserver /KSMServer logout 0 0 0 >/dev/null 2>&1 && return 0
  fi

  notify_or_print "No supported KDE logout command was found."
  return 1
}

launch_drun() {
  if ! command -v rofi >/dev/null 2>&1; then
    notify_or_print "Missing command: rofi"
    return 1
  fi

  rofi -show drun -theme "$THEME" -p "$PROMPT" || true
}

if ! command -v rofi >/dev/null 2>&1; then
  notify_or_print "Missing command: rofi"
  exit 1
fi

choices=$'terminal\nfiles\nbrowser\nsettings\napp search\nfastfetch\nlogout\nreboot\nshutdown'

selection="$(
  rofi \
    -dmenu \
    -i \
    -p "$PROMPT" \
    -theme "$THEME" \
    <<<"$choices" || true
)"

[[ -z "${selection}" ]] && exit 0

case "$selection" in
  terminal)
    run_if_exists konsole
    ;;
  files)
    run_if_exists dolphin
    ;;
  browser)
    run_if_exists xdg-open "https://google.com"
    ;;
  settings)
    run_if_exists systemsettings
    ;;
  "app search")
    launch_drun
    ;;
  fastfetch)
    run_if_exists konsole -e fastfetch
    ;;
  logout)
    run_logout
    ;;
  reboot)
    run_if_exists systemctl reboot
    ;;
  shutdown)
    run_if_exists systemctl poweroff
    ;;
  *)
    notify_or_print "Unknown selection: $selection"
    exit 1
    ;;
esac
EOF

chmod +x "$HOME/.local/bin/keskos-launcher"

log "Installed rofi theme and launcher."
