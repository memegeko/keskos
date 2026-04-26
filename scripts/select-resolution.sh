#!/usr/bin/env bash
set -euo pipefail

CONFIG_DIR="${HOME}/.config/quickshell"
ENV_FILE="${CONFIG_DIR}/keskos-resolution.env"

log() {
  printf '[select-resolution] %s\n' "$1"
}

detect_resolution() {
  local width=""
  local height=""

  if command -v kscreen-doctor >/dev/null 2>&1; then
    read -r width height < <(
      kscreen-doctor -o 2>/dev/null | awk '
        /enabled/ && match($0, /([0-9]+)x([0-9]+)/, found) {
          print found[1], found[2];
          exit;
        }
      ' || true
    )
  fi

  if [[ -z "$width" || -z "$height" ]] && command -v xrandr >/dev/null 2>&1; then
    read -r width height < <(
      xrandr --current 2>/dev/null | awk '
        / connected primary / {
          for (i = 1; i <= NF; i++) {
            if ($i ~ /^[0-9]+x[0-9]+\+[0-9]+\+[0-9]+$/) {
              split($i, parts, /x|\+/);
              print parts[1], parts[2];
              exit;
            }
          }
        }
        / connected / {
          for (i = 1; i <= NF; i++) {
            if ($i ~ /^[0-9]+x[0-9]+\+[0-9]+\+[0-9]+$/) {
              split($i, parts, /x|\+/);
              print parts[1], parts[2];
              exit;
            }
          }
        }
        match($0, /current[[:space:]]+([0-9]+)[[:space:]]+x[[:space:]]+([0-9]+)/, found) {
          print found[1], found[2];
          exit;
        }
      ' || true
    )
  fi

  if [[ -z "$width" || ! "$width" =~ ^[0-9]+$ ]]; then
    width="1920"
  fi

  if [[ -z "$height" || ! "$height" =~ ^[0-9]+$ ]]; then
    height="1080"
  fi

  printf '%s %s\n' "$width" "$height"
}

select_profile() {
  local width="$1"

  if (( width >= 3840 )); then
    printf '%s %s\n' "4k" "1.5"
  elif (( width >= 2560 )); then
    printf '%s %s\n' "1440p" "1.2"
  else
    printf '%s %s\n' "1080p" "1.0"
  fi
}

write_env_file() {
  mkdir -p "$CONFIG_DIR"

  cat >"$ENV_FILE" <<EOF
export KESKOS_QS_PROFILE=${profile}
export KESKOS_QS_SCALE=${scale_factor}
export KESKOS_QS_WIDTH=${screen_width}
export KESKOS_QS_HEIGHT=${screen_height}
EOF
}

main() {
  read -r screen_width screen_height < <(detect_resolution)
  read -r profile scale_factor < <(select_profile "$screen_width")
  write_env_file
  log "Selected ${profile} (${scale_factor}x) for ${screen_width}x${screen_height}."
}

main "$@"
