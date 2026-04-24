#!/usr/bin/env bash
set -euo pipefail

EWW_CONFIG_DIR="${HOME}/.config/eww"

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

resolve_profile() {
  local width="$1"

  if (( width >= 3840 )); then
    printf '%s\n' "profile-4k"
  elif (( width >= 2560 )); then
    printf '%s\n' "profile-1440"
  else
    printf '%s\n' "profile-1080"
  fi
}

apply_profile() {
  local profile="$1"

  case "$profile" in
    profile-4k)
      resolution_profile="profile-4k"
      hud_side_margin=152
      hud_top_offset=158
      hud_gap_top_middle=240
      hud_gap_middle_bottom=282
      hud_panel_width=770
      hud_top_left_height=304
      hud_top_right_height=344
      hud_middle_left_height=304
      hud_middle_right_height=304
      hud_bottom_left_height=344
      hud_bottom_right_height=304
      hud_key_width=236
      hud_line_spacing=8
      ;;
    profile-1440)
      resolution_profile="profile-1440"
      hud_side_margin=101
      hud_top_offset=105
      hud_gap_top_middle=160
      hud_gap_middle_bottom=188
      hud_panel_width=513
      hud_top_left_height=203
      hud_top_right_height=229
      hud_middle_left_height=203
      hud_middle_right_height=203
      hud_bottom_left_height=229
      hud_bottom_right_height=203
      hud_key_width=156
      hud_line_spacing=6
      ;;
    *)
      resolution_profile="profile-1080"
      hud_side_margin=76
      hud_top_offset=79
      hud_gap_top_middle=120
      hud_gap_middle_bottom=141
      hud_panel_width=385
      hud_top_left_height=152
      hud_top_right_height=172
      hud_middle_left_height=152
      hud_middle_right_height=152
      hud_bottom_left_height=172
      hud_bottom_right_height=152
      hud_key_width=118
      hud_line_spacing=4
      ;;
  esac
}

write_env_file() {
  mkdir -p "$EWW_CONFIG_DIR"

  cat >"$EWW_CONFIG_DIR/keskos-layout.env" <<EOF
RESOLUTION_PROFILE=${resolution_profile}
HUD_SCREEN_WIDTH=${screen_width}
HUD_SCREEN_HEIGHT=${screen_height}
HUD_SIDE_MARGIN=${hud_side_margin}
HUD_TOP_OFFSET=${hud_top_offset}
HUD_GAP_TOP_MIDDLE=${hud_gap_top_middle}
HUD_GAP_MIDDLE_BOTTOM=${hud_gap_middle_bottom}
HUD_PANEL_WIDTH=${hud_panel_width}
HUD_TOP_LEFT_HEIGHT=${hud_top_left_height}
HUD_TOP_RIGHT_HEIGHT=${hud_top_right_height}
HUD_MIDDLE_LEFT_HEIGHT=${hud_middle_left_height}
HUD_MIDDLE_RIGHT_HEIGHT=${hud_middle_right_height}
HUD_BOTTOM_LEFT_HEIGHT=${hud_bottom_left_height}
HUD_BOTTOM_RIGHT_HEIGHT=${hud_bottom_right_height}
HUD_KEY_WIDTH=${hud_key_width}
HUD_LINE_SPACING=${hud_line_spacing}
EOF
}

update_eww_vars() {
  local eww_bin=""

  if [[ -x "${HOME}/.local/bin/eww" ]]; then
    eww_bin="${HOME}/.local/bin/eww"
  elif command -v eww >/dev/null 2>&1; then
    eww_bin="$(command -v eww)"
  else
    return 0
  fi

  "$eww_bin" --config "$EWW_CONFIG_DIR" update \
    resolution_profile="$resolution_profile" \
    hud_screen_width="$screen_width" \
    hud_screen_height="$screen_height" \
    hud_side_margin="$hud_side_margin" \
    hud_top_offset="$hud_top_offset" \
    hud_gap_top_middle="$hud_gap_top_middle" \
    hud_gap_middle_bottom="$hud_gap_middle_bottom" \
    hud_panel_width="$hud_panel_width" \
    hud_top_left_height="$hud_top_left_height" \
    hud_top_right_height="$hud_top_right_height" \
    hud_middle_left_height="$hud_middle_left_height" \
    hud_middle_right_height="$hud_middle_right_height" \
    hud_bottom_left_height="$hud_bottom_left_height" \
    hud_bottom_right_height="$hud_bottom_right_height" \
    hud_key_width="$hud_key_width" \
    hud_line_spacing="$hud_line_spacing" >/dev/null 2>&1 || true
}

main() {
  read -r screen_width screen_height < <(detect_resolution)
  apply_profile "$(resolve_profile "$screen_width")"
  write_env_file
  update_eww_vars
  log "Selected ${resolution_profile} for ${screen_width}x${screen_height}."
}

main "$@"
