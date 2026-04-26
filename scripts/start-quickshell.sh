#!/usr/bin/env bash
set -euo pipefail

SCRIPT_SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_SOURCE_DIR/lib-ui.sh" ]]; then
  # shellcheck source=scripts/lib-ui.sh
  . "$SCRIPT_SOURCE_DIR/lib-ui.sh"
fi

CONFIG_DIR="${HOME}/.config/quickshell"
ENTRYPOINT="${CONFIG_DIR}/main.qml"
SELECT_RESOLUTION="${HOME}/.local/bin/keskos-select-resolution"
RESOLUTION_ENV="${CONFIG_DIR}/keskos-resolution.env"
LOG_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/keskos"
LOG_FILE="${LOG_DIR}/quickshell.log"

log() {
  if declare -F ui_log >/dev/null 2>&1; then
    ui_log "start-quickshell" "$1"
  else
    printf '[start-quickshell] %s\n' "$1"
  fi
}

resolve_quickshell_bin() {
  if [[ -x "${HOME}/.local/bin/quickshell" ]]; then
    printf '%s\n' "${HOME}/.local/bin/quickshell"
    return 0
  fi

  if command -v quickshell >/dev/null 2>&1; then
    command -v quickshell
    return 0
  fi

  return 1
}

main() {
  local quickshell_bin=""

  mkdir -p "$LOG_DIR"
  : >"$LOG_FILE"

  if ! quickshell_bin="$(resolve_quickshell_bin)"; then
    log "quickshell was not found. Skipping HUD startup."
    exit 0
  fi

  if [[ ! -f "$ENTRYPOINT" ]]; then
    log "No quickshell configuration was found in ${CONFIG_DIR}."
    exit 0
  fi

  pkill -x quickshell >/dev/null 2>&1 || true
  sleep 3

  if [[ -x "$SELECT_RESOLUTION" ]]; then
    "$SELECT_RESOLUTION" >>"$LOG_FILE" 2>&1 || true
  fi

  if [[ -f "$RESOLUTION_ENV" ]]; then
    # shellcheck disable=SC1090
    . "$RESOLUTION_ENV"
  fi

  nohup env \
    QS_NO_RELOAD_POPUP=1 \
    KESKOS_QS_PROFILE="${KESKOS_QS_PROFILE:-1080p}" \
    KESKOS_QS_SCALE="${KESKOS_QS_SCALE:-1.0}" \
    KESKOS_QS_WIDTH="${KESKOS_QS_WIDTH:-1920}" \
    KESKOS_QS_HEIGHT="${KESKOS_QS_HEIGHT:-1080}" \
    "$quickshell_bin" --path "$ENTRYPOINT" >>"$LOG_FILE" 2>&1 &

  log "Started quickshell. Log: $LOG_FILE"
}

main "$@"
