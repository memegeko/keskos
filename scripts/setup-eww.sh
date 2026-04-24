#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${1:?usage: setup-eww.sh /path/to/repo}"
EWW_REF="${KESKOS_EWW_REF:-v0.6.0}"

log() {
  printf '[setup-eww] %s\n' "$1"
}

warn() {
  printf '[setup-eww] warning: %s\n' "$1" >&2
}

fail() {
  printf '[setup-eww] error: %s\n' "$1" >&2
  exit 1
}

install_eww_config() {
  mkdir -p "$HOME/.config/eww/widgets" "$HOME/.local/bin"

  install -m 644 \
    "$REPO_DIR/configs/eww/eww.yuck" \
    "$HOME/.config/eww/eww.yuck"

  install -m 644 \
    "$REPO_DIR/configs/eww/eww.scss" \
    "$HOME/.config/eww/eww.scss"

  for widget_file in "$REPO_DIR"/configs/eww/widgets/*.yuck; do
    install -m 644 \
      "$widget_file" \
      "$HOME/.config/eww/widgets/$(basename "$widget_file")"
  done

  install -m 755 \
    "$REPO_DIR/scripts/start-eww.sh" \
    "$HOME/.local/bin/keskos-start-eww"

  install -m 755 \
    "$REPO_DIR/scripts/select-resolution.sh" \
    "$HOME/.local/bin/keskos-select-resolution"
}

write_data_helper() {
  cat >"$HOME/.local/bin/keskos-eww-data" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

SECTION="${1:-}"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/keskos"
mkdir -p "$CACHE_DIR"

json_lines() {
  jq -Rsc 'split("\n") | map(select(length > 0))'
}

trim_line() {
  local width="${1:-54}"
  awk -v max="$width" '
    {
      line=$0
      gsub(/[[:space:]]+/, " ", line)
      sub(/^ /, "", line)
      sub(/ $/, "", line)
      if (length(line) > max) {
        line = substr(line, 1, max - 3) "..."
      }
      print line
    }
  '
}

format_rate() {
  local bytes_per_second="${1:-0}"

  if (( bytes_per_second < 1024 )); then
    printf '%s B/s' "$bytes_per_second"
  elif (( bytes_per_second < 1048576 )); then
    awk -v value="$bytes_per_second" 'BEGIN { printf "%.1f KiB/s", value / 1024 }'
  elif (( bytes_per_second < 1073741824 )); then
    awk -v value="$bytes_per_second" 'BEGIN { printf "%.1f MiB/s", value / 1048576 }'
  else
    awk -v value="$bytes_per_second" 'BEGIN { printf "%.1f GiB/s", value / 1073741824 }'
  fi
}

format_kib() {
  local kib="${1:-0}"

  if (( kib < 1024 )); then
    printf '%s KiB' "$kib"
  elif (( kib < 1048576 )); then
    awk -v value="$kib" 'BEGIN { printf "%.1f MiB", value / 1024 }'
  else
    awk -v value="$kib" 'BEGIN { printf "%.1f GiB", value / 1048576 }'
  fi
}

make_bar() {
  local current="${1:-0}"
  local max="${2:-100}"
  local units="${3:-20}"
  local filled=0
  local empty=0
  local bar=""

  if (( max > 0 )); then
    filled=$(( current * units / max ))
  fi

  if (( filled < 0 )); then
    filled=0
  fi

  if (( filled > units )); then
    filled="$units"
  fi

  empty=$(( units - filled ))

  while (( filled > 0 )); do
    bar+="#"
    filled=$(( filled - 1 ))
  done

  while (( empty > 0 )); do
    bar+="."
    empty=$(( empty - 1 ))
  done

  printf '[%s]' "$bar"
}

default_interface() {
  local interface=""

  if command -v ip >/dev/null 2>&1; then
    interface="$(ip route show default 2>/dev/null | awk 'NR == 1 { print $5; exit }')"
    if [[ -z "$interface" ]]; then
      interface="$(ip -o link show 2>/dev/null | awk -F': ' '$2 != "lo" { print $2; exit }')"
    fi
  fi

  printf '%s\n' "${interface:-lo}"
}

network_speeds() {
  local interface="$1"
  local rx_file="/sys/class/net/${interface}/statistics/rx_bytes"
  local tx_file="/sys/class/net/${interface}/statistics/tx_bytes"
  local state_file="${CACHE_DIR}/eww-net-${interface}.state"
  local now rx tx last_now last_rx last_tx down up delta

  if [[ ! -r "$rx_file" || ! -r "$tx_file" ]]; then
    printf '0 0\n'
    return 0
  fi

  now="$(date +%s)"
  rx="$(<"$rx_file")"
  tx="$(<"$tx_file")"

  if [[ -r "$state_file" ]]; then
    read -r last_now last_rx last_tx <"$state_file" || true
  fi

  if [[ -z "${last_now:-}" || -z "${last_rx:-}" || -z "${last_tx:-}" ]]; then
    last_now="$now"
    last_rx="$rx"
    last_tx="$tx"
  fi

  delta=$(( now - last_now ))
  if (( delta <= 0 )); then
    delta=1
  fi

  down=$(( (rx - last_rx) / delta ))
  up=$(( (tx - last_tx) / delta ))

  if (( down < 0 )); then
    down=0
  fi

  if (( up < 0 )); then
    up=0
  fi

  printf '%s %s %s\n' "$now" "$rx" "$tx" >"$state_file"
  printf '%s %s\n' "$down" "$up"
}

print_system_status() {
  local pretty_name="Arch Linux"
  local kernel uptime shell_name session_name wm_name

  if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    pretty_name="${PRETTY_NAME:-Arch Linux}"
  fi

  kernel="$(uname -r 2>/dev/null || printf 'unknown')"
  uptime="$(uptime -p 2>/dev/null | sed 's/^up //')"
  shell_name="$(basename "${SHELL:-sh}")"
  session_name="${XDG_CURRENT_DESKTOP:-KDE Plasma}"
  wm_name="KWin / ${XDG_SESSION_TYPE:-wayland}"

  jq -nc \
    --arg os "$pretty_name" \
    --arg kernel "$kernel" \
    --arg uptime "${uptime:-n/a}" \
    --arg shell "$shell_name" \
    --arg session "$session_name" \
    --arg wm "$wm_name" \
    '{os:$os,kernel:$kernel,uptime:$uptime,shell:$shell,session:$session,wm:$wm}'
}

print_network() {
  local interface status local_ip down up

  interface="$(default_interface)"
  status="offline"

  if [[ -r "/sys/class/net/${interface}/operstate" ]]; then
    status="$(<"/sys/class/net/${interface}/operstate")"
  fi

  local_ip="$(
    ip -4 addr show dev "$interface" 2>/dev/null | awk '/inet / { print $2; exit }'
  )"

  read -r down up < <(network_speeds "$interface")

  jq -nc \
    --arg interface "$interface" \
    --arg status "$status" \
    --arg local_ip "${local_ip:-n/a}" \
    --arg down "$(format_rate "$down")" \
    --arg up "$(format_rate "$up")" \
    '{interface:$interface,status:$status,local_ip:$local_ip,down:$down,up:$up}'
}

print_system_log() {
  local fallback

  if command -v journalctl >/dev/null 2>&1; then
    if journalctl -n 8 --no-pager >/dev/null 2>&1; then
      journalctl -n 8 --no-pager 2>/dev/null \
        | sed 's/^[[:space:]]*//' \
        | tail -n 8 \
        | trim_line 54 \
        | json_lines
      return 0
    fi
  fi

  fallback=$'BOOTSTRAP CHANNEL READY\nDISPLAY BUS LINKED\nSYSTEM PROFILE LOADED\nWAYLAND HUD SYNCED\nPLASMA SESSION STABLE\nROFI COMMAND LAYER IDLE\nMEMORY TELEMETRY NOMINAL\nNETWORK WATCH ACTIVE'
  printf '%s\n' "$fallback" | json_lines
}

print_system_profile() {
  local host_name user_name machine_name session_name uptime_text

  host_name="$(hostname 2>/dev/null || printf 'kesk-node')"
  user_name="$(id -un 2>/dev/null || printf '%s' "${USER:-user}")"
  machine_name="$(uname -m 2>/dev/null || printf 'unknown')"
  session_name="${XDG_CURRENT_DESKTOP:-KDE Plasma} / ${XDG_SESSION_TYPE:-wayland}"
  uptime_text="$(uptime -p 2>/dev/null | sed 's/^up //')"

  jq -nc \
    --arg host "$host_name" \
    --arg user "$user_name" \
    --arg machine "$machine_name" \
    --arg session "$session_name" \
    --arg uptime "${uptime_text:-n/a}" \
    --arg node "KESK-01" \
    --arg access "GRANTED" \
    '{host:$host,user:$user,machine:$machine,session:$session,uptime:$uptime,node:$node,access:$access}'
}

print_memory() {
  local total_kib available_kib used_kib percent

  total_kib="$(awk '/MemTotal:/ { print $2; exit }' /proc/meminfo 2>/dev/null || printf '0')"
  available_kib="$(awk '/MemAvailable:/ { print $2; exit }' /proc/meminfo 2>/dev/null || printf '0')"
  used_kib=$(( total_kib - available_kib ))

  if (( total_kib > 0 )); then
    percent=$(( used_kib * 100 / total_kib ))
  else
    percent=0
  fi

  jq -nc \
    --arg total "$(format_kib "$total_kib")" \
    --arg used "$(format_kib "$used_kib")" \
    --arg percent "${percent}%" \
    --arg bar "$(make_bar "$used_kib" "$total_kib" 20)" \
    '{total:$total,used:$used,percent:$percent,bar:$bar}'
}

case "$SECTION" in
  system-status)
    print_system_status
    ;;
  network)
    print_network
    ;;
  system-log)
    print_system_log
    ;;
  system-profile)
    print_system_profile
    ;;
  memory)
    print_memory
    ;;
  *)
    jq -nc '{}'
    ;;
esac
EOF

  chmod +x "$HOME/.local/bin/keskos-eww-data"
}

cleanup_conky_state() {
  rm -rf "$HOME/.config/conky"
  rm -f "$HOME/.config/autostart/keskos-conky.desktop"
  rm -f "$HOME/.local/bin/keskos-start-conky"
  rm -f "$HOME/.local/bin/keskos-conky-block"
  rm -f "$HOME/.local/bin/keskos-select-resolution-profile"
  pkill -x conky >/dev/null 2>&1 || true
}

build_eww_from_source() {
  local src_dir="$HOME/.cache/keskos/eww-src"

  if [[ -x "$HOME/.local/bin/eww" && "${KESKOS_REBUILD_EWW:-0}" != "1" ]]; then
    log "Keeping the existing local eww binary at $HOME/.local/bin/eww."
    return 0
  fi

  rm -rf "$src_dir"

  log "Cloning eww ${EWW_REF} from the official repository..."
  git clone --branch "$EWW_REF" --depth 1 https://github.com/elkowar/eww "$src_dir"

  log "Building eww with Wayland support..."
  (
    cd "$src_dir"
    cargo build --release --no-default-features --features=wayland
  )

  install -m 755 "$src_dir/target/release/eww" "$HOME/.local/bin/eww"
  log "Installed the locally built eww binary to $HOME/.local/bin/eww."
}

main() {
  install_eww_config
  write_data_helper
  cleanup_conky_state
  build_eww_from_source
  log "Installed the Eww HUD configuration and startup helpers."
}

main "$@"
