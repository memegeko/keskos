#!/usr/bin/env bash
set -euo pipefail

log() {
  printf '[select-resolution-profile] %s\n' "$1"
}

fail() {
  printf '[select-resolution-profile] error: %s\n' "$1" >&2
  exit 1
}

detect_screen_width() {
  local width=""

  if command -v xrandr >/dev/null 2>&1; then
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

  if [[ -z "$width" ]] && command -v kscreen-doctor >/dev/null 2>&1; then
    width="$(
      kscreen-doctor -o 2>/dev/null | awk '
        /enabled/ && match($0, /([0-9]+)x([0-9]+)/, found) {
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

detect_network_interface() {
  local interface=""

  if command -v ip >/dev/null 2>&1; then
    interface="$(
      ip route show default 2>/dev/null | awk 'NR == 1 { print $5; exit }'
    )"

    if [[ -z "$interface" ]]; then
      interface="$(
        ip -o link show 2>/dev/null | awk -F': ' '$2 != "lo" { print $2; exit }'
      )"
    fi
  fi

  if [[ -z "$interface" ]]; then
    interface="lo"
  fi

  printf '%s\n' "$interface"
}

main() {
  local conky_dir="$HOME/.config/conky"
  local profile_dir="$conky_dir/profiles"
  local width interface profile_name source_profile target_profile

  mkdir -p "$conky_dir"

  width="$(detect_screen_width)"
  interface="$(detect_network_interface)"

  if (( width >= 3840 )); then
    profile_name="keskos-4k.conf"
  elif (( width >= 2560 )); then
    profile_name="keskos-1440p.conf"
  else
    profile_name="keskos-1080p.conf"
  fi

  source_profile="${profile_dir}/${profile_name}"
  target_profile="${conky_dir}/keskos.conf"

  if [[ ! -f "$source_profile" ]]; then
    fail "Profile ${source_profile} was not found. Run setup-conky.sh first."
  fi

  sed "s|__NET_IFACE__|${interface}|g" "$source_profile" >"$target_profile"

  cat >"$conky_dir/keskos.env" <<EOF
PROFILE=${profile_name}
SCREEN_WIDTH=${width}
NETWORK_INTERFACE=${interface}
EOF

  log "Selected ${profile_name} for ${width}px using interface ${interface}."
}

main "$@"
