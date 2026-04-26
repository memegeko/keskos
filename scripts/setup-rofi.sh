#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${1:?usage: setup-rofi.sh /path/to/repo}"

log() {
  printf '[setup-rofi] %s\n' "$1"
}

install_backend() {
  local source_root="$REPO_DIR/launcher"
  local target_root="$HOME/.local/share/keskos/launcher"
  local file_path=""
  local relative_path=""

  mkdir -p "$target_root"
  rm -rf "$target_root/kesk_runner"

  while IFS= read -r file_path; do
    relative_path="${file_path#"$source_root"/}"
    install -Dm644 "$file_path" "$target_root/$relative_path"
  done < <(find "$source_root" -type f -name '*.py' | sort)
}

install_wrappers() {
  cat >"$HOME/.local/bin/keskos-launcher" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

THEME="${HOME}/.config/rofi/keskos.rasi"
CONFIG="${HOME}/.config/rofi/keskos-launcher-config.rasi"
LAUNCHER_ROOT="${HOME}/.local/share/keskos/launcher"
SCRIPT_BIN="${HOME}/.local/bin/keskos-launcher-script"
MODE="main"
ACTION=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode)
      MODE="${2:-main}"
      shift 2
      ;;
    --action)
      ACTION="${2:-}"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

export PYTHONPATH="${LAUNCHER_ROOT}${PYTHONPATH:+:${PYTHONPATH}}"

if [[ -n "$ACTION" ]]; then
  exec python3 -m kesk_runner action "$ACTION"
fi

case "$MODE" in
  main|apps|windows|settings|power)
    ;;
  *)
    MODE="main"
    ;;
esac

(
  python3 -m kesk_runner warm --sync-files >/dev/null 2>&1
) &

ROFI_MODES="kesk-main:${SCRIPT_BIN} main,kesk-apps:${SCRIPT_BIN} apps,kesk-windows:${SCRIPT_BIN} windows,kesk-settings:${SCRIPT_BIN} settings,kesk-power:${SCRIPT_BIN} power"
SHOW_MODE="kesk-${MODE}"

exec rofi \
  -show "$SHOW_MODE" \
  -modes "$ROFI_MODES" \
  -config "$CONFIG" \
  -theme "$THEME" \
  -i \
  -no-sort \
  -matching normal
EOF

  cat >"$HOME/.local/bin/keskos-launcher-script" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-main}"
LAUNCHER_ROOT="${HOME}/.local/share/keskos/launcher"
shift || true

export PYTHONPATH="${LAUNCHER_ROOT}${PYTHONPATH:+:${PYTHONPATH}}"
exec python3 -m kesk_runner script --mode "$MODE" --entry-text "${*:-}"
EOF

  chmod +x "$HOME/.local/bin/keskos-launcher" "$HOME/.local/bin/keskos-launcher-script"
}

main() {
  mkdir -p "$HOME/.config/rofi" "$HOME/.local/bin" "$HOME/.local/share/applications" "$HOME/.local/share/keskos/launcher"

  install -m 644 \
    "$REPO_DIR/configs/rofi/keskos.rasi" \
    "$HOME/.config/rofi/keskos.rasi"

  install -m 644 \
    "$REPO_DIR/configs/rofi/keskos-launcher-config.rasi" \
    "$HOME/.config/rofi/keskos-launcher-config.rasi"

  install_backend
  install_wrappers

  PYTHONPATH="$HOME/.local/share/keskos/launcher${PYTHONPATH:+:${PYTHONPATH}}" \
    python3 -m kesk_runner warm --sync-files >/dev/null 2>&1 || true

  log "Installed the rofi theme, launcher config, Kesk runner backend, and launcher wrappers."
}

main "$@"
