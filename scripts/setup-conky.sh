#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${1:?usage: setup-conky.sh /path/to/repo}"

log() {
  printf '[setup-conky] %s\n' "$1"
}

fail() {
  printf '[setup-conky] error: %s\n' "$1" >&2
  exit 1
}

mkdir -p "$HOME/.config/conky/profiles" "$HOME/.local/bin" "$HOME/.cache/keskos"

for profile in \
  "$REPO_DIR/configs/conky/keskos-1080p.conf" \
  "$REPO_DIR/configs/conky/keskos-1440p.conf" \
  "$REPO_DIR/configs/conky/keskos-4k.conf"; do
  if [[ ! -f "$profile" ]]; then
    fail "Missing Conky profile: $profile"
  fi

  install -m 644 \
    "$profile" \
    "$HOME/.config/conky/profiles/$(basename "$profile")"
done

install -m 644 \
  "$REPO_DIR/configs/conky/keskos.conf.template" \
  "$HOME/.config/conky/keskos.conf.template"

install -m 755 \
  "$REPO_DIR/scripts/select-resolution-profile.sh" \
  "$HOME/.local/bin/keskos-select-resolution-profile"

cat >"$HOME/.local/bin/keskos-conky-block" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

BLOCK="${1:-}"
X="${2:-60}"
WIDTH="${3:-42}"
HEADER_SIZE="${4:-16}"
BODY_SIZE="${5:-12}"
IFACE="${6:-}"
CACHE_DIR="${HOME}/.cache/keskos"

mkdir -p "$CACHE_DIR"

goto_line() {
  printf '${goto %s}' "$X"
}

sanitize() {
  printf '%s' "${1:-}" | tr '\n' ' ' | tr -cd '[:print:]\t ' | sed 's/[$]/ /g; s/[[:space:]]\+/ /g; s/^ //; s/ $//'
}

fit() {
  local input max
  input="$(sanitize "${1:-}")"
  max="${2:-40}"

  if (( ${#input} > max )); then
    printf '%s' "${input:0:max-3}..."
  else
    printf '%s' "$input"
  fi
}

header() {
  printf '%s${font JetBrainsMono Nerd Font:size=%s:bold}%s${font JetBrainsMono Nerd Font:size=%s}\n' \
    "$(goto_line)" "$HEADER_SIZE" "$1" "$BODY_SIZE"
}

line_item() {
  local label="$1"
  local value="$2"
  local label_width=15
  local value_width=$(( WIDTH - label_width - 1 ))

  if (( value_width < 8 )); then
    value_width=8
  fi

  printf '%s%-*s %s\n' \
    "$(goto_line)" \
    "$label_width" \
    "$label" \
    "$(fit "$value" "$value_width")"
}

make_bar() {
  local current="$1"
  local max="$2"
  local units="${3:-18}"
  local filled=0
  local empty=0
  local bar=""

  if (( max > 0 )); then
    filled=$(( current * units / max ))
  fi

  if (( filled > units )); then
    filled="$units"
  fi

  if (( filled < 0 )); then
    filled=0
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

  printf '%s' "$bar"
}

format_bytes_mib() {
  local kib="$1"

  if (( kib >= 1048576 )); then
    awk -v value="$kib" 'BEGIN { printf "%.1f GiB", value / 1048576 }'
  elif (( kib >= 1024 )); then
    awk -v value="$kib" 'BEGIN { printf "%.1f MiB", value / 1024 }'
  else
    printf '%s KiB' "$kib"
  fi
}

format_rate() {
  local bytes_per_second="$1"
  local kib_per_second=$(( bytes_per_second / 1024 ))

  if (( kib_per_second >= 1048576 )); then
    awk -v value="$kib_per_second" 'BEGIN { printf "%.1f GiB/s", value / 1048576 }'
  elif (( kib_per_second >= 1024 )); then
    awk -v value="$kib_per_second" 'BEGIN { printf "%.1f MiB/s", value / 1024 }'
  else
    printf '%s KiB/s' "$kib_per_second"
  fi
}

cache_is_fresh() {
  local stamp_file="$1"
  local max_age="$2"
  local now cached_ts

  now="$(date +%s)"

  if [[ ! -r "$stamp_file" ]]; then
    return 1
  fi

  read -r cached_ts <"$stamp_file" || return 1
  [[ "$cached_ts" =~ ^[0-9]+$ ]] || return 1
  (( now - cached_ts < max_age ))
}

write_cache_stamp() {
  local stamp_file="$1"
  date +%s >"$stamp_file"
}

default_interface() {
  local interface="$IFACE"

  if [[ -z "$interface" ]] && command -v ip >/dev/null 2>&1; then
    interface="$(ip route show default 2>/dev/null | awk 'NR == 1 { print $5; exit }')"
  fi

  if [[ -z "$interface" ]]; then
    interface="lo"
  fi

  printf '%s\n' "$interface"
}

packages_count() {
  local value cache_file stamp_file
  cache_file="${CACHE_DIR}/packages-count.cache"
  stamp_file="${CACHE_DIR}/packages-count.stamp"

  if cache_is_fresh "$stamp_file" 21600 && [[ -r "$cache_file" ]]; then
    cat "$cache_file"
    return 0
  fi

  if command -v pacman >/dev/null 2>&1; then
    value="$(pacman -Qq 2>/dev/null | wc -l | tr -d ' ')"
  else
    value="n/a"
  fi

  printf '%s\n' "$value" >"$cache_file"
  write_cache_stamp "$stamp_file"
  printf '%s\n' "$value"
}

first_dns() {
  if [[ -r /etc/resolv.conf ]]; then
    awk '/^nameserver/ { print $2; exit }' /etc/resolv.conf
  fi
}

network_speed_snapshot() {
  local interface="$1"
  local rx_file="/sys/class/net/${interface}/statistics/rx_bytes"
  local tx_file="/sys/class/net/${interface}/statistics/tx_bytes"
  local state_file="${CACHE_DIR}/network-${interface}.state"
  local now rx tx last_now last_rx last_tx delta_time down_bps up_bps

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

  delta_time=$(( now - last_now ))
  if (( delta_time <= 0 )); then
    delta_time=1
  fi

  down_bps=$(( (rx - last_rx) / delta_time ))
  up_bps=$(( (tx - last_tx) / delta_time ))

  if (( down_bps < 0 )); then
    down_bps=0
  fi

  if (( up_bps < 0 )); then
    up_bps=0
  fi

  printf '%s %s %s\n' "$now" "$rx" "$tx" >"$state_file"
  printf '%s %s\n' "$down_bps" "$up_bps"
}

system_log_lines() {
  local width_chars="$1"
  local log_width="$(( width_chars - 2 ))"
  local cache_file="${CACHE_DIR}/system-log.cache"
  local stamp_file="${CACHE_DIR}/system-log.stamp"

  if cache_is_fresh "$stamp_file" 60 && [[ -r "$cache_file" ]]; then
    cat "$cache_file"
    return 0
  fi

  if command -v journalctl >/dev/null 2>&1; then
    if journalctl --user -n 8 --no-pager -o cat >/dev/null 2>&1; then
      journalctl --user -n 8 --no-pager -o cat 2>/dev/null \
        | sed 's/[[:space:]]\+/ /g; s/^ //; s/ $//' \
        | awk 'NF' \
        | tail -n 8 \
        | while IFS= read -r line; do
            fit "$line" "$log_width"
            printf '\n'
          done >"$cache_file"
      write_cache_stamp "$stamp_file"
      cat "$cache_file"
      return 0
    fi

    if journalctl -n 8 --no-pager -o short-monotonic >/dev/null 2>&1; then
      journalctl -n 8 --no-pager -o short-monotonic 2>/dev/null \
        | sed 's/[[:space:]]\+/ /g; s/^ //; s/ $//' \
        | awk 'NF' \
        | tail -n 8 \
        | while IFS= read -r line; do
            fit "$line" "$log_width"
            printf '\n'
          done >"$cache_file"
      write_cache_stamp "$stamp_file"
      cat "$cache_file"
      return 0
    fi
  fi

  printf '%s\n' \
    "$(fit 'service layer synced' "$log_width")" \
    "$(fit 'wallpaper pipeline ready' "$log_width")" \
    "$(fit 'display bus nominal' "$log_width")" \
    "$(fit 'plasma session active' "$log_width")" \
    "$(fit 'rofi command layer idle' "$log_width")" \
    "$(fit 'conky hud watching' "$log_width")" \
    "$(fit 'network monitor armed' "$log_width")" \
    "$(fit 'memory profile stable' "$log_width")" >"$cache_file"
  write_cache_stamp "$stamp_file"
  cat "$cache_file"
}

print_system_status() {
  local pretty_name kernel uptime packages shell_name session_name

  pretty_name="Arch Linux"
  if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    pretty_name="${PRETTY_NAME:-Arch Linux}"
  fi
  kernel="$(uname -r 2>/dev/null || printf 'unknown')"
  uptime="$(uptime -p 2>/dev/null | sed 's/^up //')"
  packages="$(packages_count)"
  shell_name="$(basename "${SHELL:-sh}")"
  session_name="${XDG_CURRENT_DESKTOP:-KDE Plasma}"

  header "SYSTEM STATUS"
  line_item "OS" "$pretty_name"
  line_item "KERNEL" "$kernel"
  line_item "UPTIME" "${uptime:-n/a}"
  line_item "PACKAGES" "$packages"
  line_item "SHELL" "$shell_name"
  line_item "WM / DE" "KWin / ${session_name}"
  line_item "TERMINAL" "konsole"
}

print_core_modules() {
  local net_manager="MISS"
  local file_system="OK"
  local processor="MISS"
  local memory="MISS"
  local audio="MISS"
  local display="MISS"
  local sys_monitor="MISS"

  command -v conky >/dev/null 2>&1 && sys_monitor="OK"
  command -v ip >/dev/null 2>&1 && net_manager="OK"
  [[ -d /proc ]] && processor="OK"
  [[ -r /proc/meminfo ]] && memory="OK"
  if pgrep -x pipewire >/dev/null 2>&1 || command -v pactl >/dev/null 2>&1; then
    audio="OK"
  fi
  if [[ -n "${DISPLAY:-}" || -n "${WAYLAND_DISPLAY:-}" || -n "${XDG_SESSION_TYPE:-}" ]]; then
    display="OK"
  fi

  header "CORE MODULES"
  line_item "SYS_MONITOR" "$sys_monitor"
  line_item "NET_MANAGER" "$net_manager"
  line_item "FILE_SYSTEM" "$file_system"
  line_item "PROCESSOR" "$processor"
  line_item "MEMORY" "$memory"
  line_item "AUDIO_ENGINE" "$audio"
  line_item "DISPLAY_SERVER" "$display"
}

print_network() {
  local interface operstate local_ip gateway dns_server down_bps up_bps down_bar up_bar

  interface="$(default_interface)"
  operstate="offline"
  if [[ -r "/sys/class/net/${interface}/operstate" ]]; then
    operstate="$(<"/sys/class/net/${interface}/operstate")"
  fi

  local_ip="$(
    ip -4 addr show dev "$interface" 2>/dev/null | awk '/inet / { print $2; exit }'
  )"
  gateway="$(
    ip route show default 2>/dev/null | awk 'NR == 1 { print $3; exit }'
  )"
  dns_server="$(first_dns)"
  read -r down_bps up_bps < <(network_speed_snapshot "$interface")
  down_bar="$(make_bar "$down_bps" 8388608 18)"
  up_bar="$(make_bar "$up_bps" 8388608 18)"

  header "NETWORK"
  line_item "STATUS" "$operstate"
  line_item "INTERFACE" "$interface"
  line_item "LOCAL IP" "${local_ip:-n/a}"
  line_item "GATEWAY" "${gateway:-n/a}"
  line_item "DNS" "${dns_server:-n/a}"
  line_item "DOWN" "$(format_rate "$down_bps")"
  line_item "UP" "$(format_rate "$up_bps")"
  line_item "RX BAR" "[$down_bar]"
  line_item "TX BAR" "[$up_bar]"
}

print_system_log() {
  header "SYSTEM LOG"

  while IFS= read -r line; do
    printf '%s%s\n' "$(goto_line)" "$line"
  done < <(system_log_lines "$WIDTH")
}

print_quick_access() {
  local session_name host_name user_name device_name

  session_name="${XDG_CURRENT_DESKTOP:-KDE Plasma}"
  host_name="$(hostname 2>/dev/null || printf 'kesk-node-01')"
  user_name="$(id -un 2>/dev/null || printf '%s' "${USER:-user}")"
  device_name="$(uname -m 2>/dev/null || printf 'unknown')"

  header "QUICK ACCESS"
  line_item "META+K" "command layer"
  line_item "APP SEARCH" "rofi drun"
  line_item "TERMINAL" "konsole"
  line_item "FILES" "dolphin"
  line_item "HOST" "$host_name"
  line_item "USER" "$user_name"
  line_item "SESSION" "$session_name"
  line_item "DEVICE" "$device_name"
}

print_memory() {
  local total_kib available_kib used_kib used_percent bar

  total_kib="$(awk '/MemTotal:/ { print $2; exit }' /proc/meminfo 2>/dev/null)"
  available_kib="$(awk '/MemAvailable:/ { print $2; exit }' /proc/meminfo 2>/dev/null)"

  if [[ -z "$total_kib" || -z "$available_kib" ]]; then
    total_kib=0
    available_kib=0
  fi

  used_kib=$(( total_kib - available_kib ))
  if (( total_kib > 0 )); then
    used_percent=$(( used_kib * 100 / total_kib ))
  else
    used_percent=0
  fi

  bar="$(make_bar "$used_kib" "$total_kib" 18)"

  header "MEMORY"
  line_item "TOTAL RAM" "$(format_bytes_mib "$total_kib")"
  line_item "USED RAM" "$(format_bytes_mib "$used_kib")"
  line_item "FREE RAM" "$(format_bytes_mib "$available_kib")"
  line_item "USAGE" "${used_percent}%"
  line_item "BAR" "[$bar]"
}

case "$BLOCK" in
  system-status)
    print_system_status
    ;;
  core-modules)
    print_core_modules
    ;;
  network)
    print_network
    ;;
  system-log)
    print_system_log
    ;;
  quick-access)
    print_quick_access
    ;;
  memory)
    print_memory
    ;;
  *)
    exit 0
    ;;
esac
EOF

chmod +x "$HOME/.local/bin/keskos-conky-block"

cat >"$HOME/.local/bin/keskos-start-conky" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

CONFIG="${HOME}/.config/conky/keskos.conf"
SELECTOR="${HOME}/.local/bin/keskos-select-resolution-profile"

if [[ -z "${DISPLAY:-}" && -z "${WAYLAND_DISPLAY:-}" ]]; then
  exit 0
fi

if ! command -v conky >/dev/null 2>&1; then
  exit 0
fi

pkill -f "conky.*${CONFIG}" >/dev/null 2>&1 || true

if [[ -x "$SELECTOR" ]]; then
  "$SELECTOR" >/dev/null 2>&1 || true
fi

if [[ ! -f "$CONFIG" ]]; then
  exit 0
fi

sleep 3
nohup conky -c "$CONFIG" >/dev/null 2>&1 &
EOF

chmod +x "$HOME/.local/bin/keskos-start-conky"

"$HOME/.local/bin/keskos-select-resolution-profile" >/dev/null 2>&1 || true

log "Installed Conky profiles, helpers, and the HUD startup script."
