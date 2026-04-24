#!/usr/bin/env bash
set -euo pipefail

EWW_CONFIG_DIR="${HOME}/.config/eww"
SELECT_RESOLUTION="${HOME}/.local/bin/keskos-select-resolution"

log() {
  printf '[start-eww] %s\n' "$1"
}

resolve_eww_bin() {
  if [[ -x "${HOME}/.local/bin/eww" ]]; then
    printf '%s\n' "${HOME}/.local/bin/eww"
    return 0
  fi

  if command -v eww >/dev/null 2>&1; then
    command -v eww
    return 0
  fi

  return 1
}

main() {
  local eww_bin=""

  if ! eww_bin="$(resolve_eww_bin)"; then
    log "eww was not found. Skipping HUD startup."
    exit 0
  fi

  if [[ ! -f "${EWW_CONFIG_DIR}/eww.yuck" ]]; then
    log "No eww configuration was found in ${EWW_CONFIG_DIR}."
    exit 0
  fi

  "$eww_bin" --config "$EWW_CONFIG_DIR" close-all >/dev/null 2>&1 || true
  "$eww_bin" --config "$EWW_CONFIG_DIR" kill >/dev/null 2>&1 || true
  pkill -x eww >/dev/null 2>&1 || true

  sleep 2

  if [[ -x "$SELECT_RESOLUTION" ]]; then
    "$SELECT_RESOLUTION" >/dev/null 2>&1 || true
  fi

  "$eww_bin" --config "$EWW_CONFIG_DIR" daemon >/dev/null 2>&1 || true
  sleep 1

  if [[ -x "$SELECT_RESOLUTION" ]]; then
    "$SELECT_RESOLUTION" >/dev/null 2>&1 || true
  fi

  "$eww_bin" --config "$EWW_CONFIG_DIR" open hud >/dev/null 2>&1
}

main "$@"
