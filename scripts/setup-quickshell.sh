#!/usr/bin/env bash
set -euo pipefail

SCRIPT_SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_SOURCE_DIR/lib-ui.sh" ]]; then
  # shellcheck source=scripts/lib-ui.sh
  . "$SCRIPT_SOURCE_DIR/lib-ui.sh"
fi

REPO_DIR="${1:?usage: setup-quickshell.sh /path/to/repo}"
QUICKSHELL_REF="${KESKOS_QUICKSHELL_REF:-master}"

log() {
  if declare -F ui_log >/dev/null 2>&1; then
    ui_log "setup-quickshell" "$1"
  else
    printf '[setup-quickshell] %s\n' "$1"
  fi
}

warn() {
  if declare -F ui_warn >/dev/null 2>&1; then
    ui_warn "setup-quickshell" "$1"
  else
    printf '[setup-quickshell] warning: %s\n' "$1" >&2
  fi
}

fail() {
  if declare -F ui_error >/dev/null 2>&1; then
    ui_error "setup-quickshell" "$1"
  else
    printf '[setup-quickshell] error: %s\n' "$1" >&2
  fi
  exit 1
}

backup_file() {
  local file_path="$1"

  if [[ -f "$file_path" && ! -f "${file_path}.keskos.bak" ]]; then
    cp "$file_path" "${file_path}.keskos.bak"
  fi
}

install_quickshell_dependencies() {
  local packages=(
    jq
    lm_sensors
    procps-ng
    iproute2
    qt6-base
    qt6-declarative
    qt6-wayland
    qt6-5compat
    qt6-svg
    qt6-shadertools
    git
    base-devel
    cmake
    ninja
    pkgconf
    cli11
    libdrm
    wayland
    wayland-protocols
    vulkan-headers
    spirv-tools
  )

  if ! command -v sudo >/dev/null 2>&1; then
    fail "sudo is required to install Quickshell dependencies."
  fi

  log "Installing Quickshell runtime and build dependencies..."
  sudo pacman -S --needed "${packages[@]}"
}

write_data_helper() {
  cat >"$HOME/.local/bin/keskos-quickshell-data" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

SECTION="${1:-}"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/keskos"
mkdir -p "$CACHE_DIR"

json_lines() {
  jq -Rsc 'split("\n") | map(select(length > 0))'
}

trim_line() {
  local width="${1:-72}"
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
    awk -v value="$bytes_per_second" 'BEGIN { printf "%.0f KB/s", value / 1024 }'
  elif (( bytes_per_second < 1073741824 )); then
    awk -v value="$bytes_per_second" 'BEGIN { printf "%.2f MB/s", value / 1048576 }'
  else
    awk -v value="$bytes_per_second" 'BEGIN { printf "%.2f GB/s", value / 1073741824 }'
  fi
}

format_kib() {
  local kib="${1:-0}"

  if (( kib < 1024 )); then
    printf '%s KiB' "$kib"
  elif (( kib < 1048576 )); then
    awk -v value="$kib" 'BEGIN { printf "%.2f MiB", value / 1024 }'
  else
    awk -v value="$kib" 'BEGIN { printf "%.2f GiB", value / 1048576 }'
  fi
}

title_case() {
  local raw="${1:-}"
  awk -v text="$raw" 'BEGIN {
    text=tolower(text)
    first=toupper(substr(text, 1, 1))
    rest=substr(text, 2)
    printf "%s%s", first, rest
  }'
}

shell_display() {
  local shell_bin shell_name version=""

  shell_bin="${SHELL:-sh}"
  shell_name="$(basename "$shell_bin")"

  case "$shell_name" in
    bash)
      version="${BASH_VERSION%%(*}"
      ;;
    zsh)
      version="$(zsh --version 2>/dev/null | awk '{print $2}' | head -n 1 || true)"
      ;;
    fish)
      version="$(fish --version 2>/dev/null | awk '{print $3}' | head -n 1 || true)"
      ;;
    *)
      version="$("$shell_bin" --version 2>/dev/null | head -n 1 | awk '{print $NF}' || true)"
      ;;
  esac

  if [[ -n "$version" ]]; then
    printf '%s %s\n' "$shell_name" "$version"
  else
    printf '%s\n' "$shell_name"
  fi
}

pretty_session() {
  local desktop session_type

  desktop="${XDG_CURRENT_DESKTOP:-KDE Plasma}"
  session_type="$(title_case "${XDG_SESSION_TYPE:-wayland}")"
  printf '%s (%s)\n' "$desktop" "$session_type"
}

append_history_line() {
  local history_line="${1:-}"
  local sample="${2:-0}"
  local limit="${3:-16}"
  local -a values=()

  if [[ -n "$history_line" ]]; then
    read -r -a values <<< "$history_line"
  fi

  values+=("$sample")

  while (( ${#values[@]} > limit )); do
    values=("${values[@]:1}")
  done

  while (( ${#values[@]} < limit )); do
    values=(0 "${values[@]}")
  done

  if (( ${#values[@]} == 0 )); then
    values=(0)
  fi

  printf '%s\n' "${values[*]}"
}

normalize_history_line() {
  local history_line="${1:-0}"
  local -a values=()
  local max_value=1
  local value

  read -r -a values <<< "$history_line"

  if (( ${#values[@]} == 0 )); then
    values=(0)
  fi

  for value in "${values[@]}"; do
    if (( value > max_value )); then
      max_value="$value"
    fi
  done

  printf '%s\n' "${values[@]}" \
    | jq -Rsc --argjson max "$max_value" '
        split("\n")
        | map(select(length > 0) | tonumber)
        | map(if $max > 0 then ((. / $max * 100) | round) else 0 end)
      '
}

connection_type() {
  local interface="${1:-lo}"

  if [[ -d "/sys/class/net/${interface}/wireless" ]]; then
    printf 'Wi-Fi\n'
  elif [[ "$interface" == "lo" ]]; then
    printf 'Loopback\n'
  else
    printf 'Wired\n'
  fi
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
  local state_file="${CACHE_DIR}/qs-net-${interface}.state"
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
  local kernel uptime shell_name session_name

  if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    pretty_name="${PRETTY_NAME:-Arch Linux}"
  fi

  kernel="$(uname -r 2>/dev/null || printf 'unknown')"
  uptime="$(uptime -p 2>/dev/null | sed 's/^up //')"
  shell_name="$(shell_display)"
  session_name="$(pretty_session)"

  jq -nc \
    --arg os "$pretty_name" \
    --arg kernel "$kernel" \
    --arg uptime "${uptime:-n/a}" \
    --arg shell "$shell_name" \
    --arg session "$session_name" \
    '{os:$os,kernel:$kernel,uptime:$uptime,shell:$shell,session:$session}'
}

print_network() {
  local interface operstate local_ip gateway down up status connection
  local history_file history_down history_up down_line up_line down_json up_json

  interface="$(default_interface)"
  operstate="down"

  if [[ -r "/sys/class/net/${interface}/operstate" ]]; then
    operstate="$(<"/sys/class/net/${interface}/operstate")"
  fi

  local_ip="$(ip -4 addr show dev "$interface" 2>/dev/null | awk '/inet / { print $2; exit }')"
  gateway="$(ip route show default 2>/dev/null | awk 'NR == 1 { print $3; exit }')"

  read -r down up < <(network_speeds "$interface")

  history_file="${CACHE_DIR}/qs-net-${interface}.history"
  if [[ -r "$history_file" ]]; then
    history_down="$(sed -n '1p' "$history_file")"
    history_up="$(sed -n '2p' "$history_file")"
  fi

  down_line="$(append_history_line "${history_down:-}" "$down" 16)"
  up_line="$(append_history_line "${history_up:-}" "$up" 16)"
  printf '%s\n%s\n' "$down_line" "$up_line" >"$history_file"

  down_json="$(normalize_history_line "$down_line")"
  up_json="$(normalize_history_line "$up_line")"

  connection="$(connection_type "$interface")"
  if [[ -n "${local_ip:-}" && "$operstate" == "up" ]]; then
    status="ONLINE"
  else
    status="OFFLINE"
    if [[ "$interface" != "lo" ]]; then
      connection="Disconnected"
    fi
  fi

  jq -nc \
    --arg interface "$interface" \
    --arg connection "$connection" \
    --arg status "$status" \
    --arg local_ip "${local_ip:-n/a}" \
    --arg gateway "${gateway:-n/a}" \
    --arg down "$(format_rate "$down")" \
    --arg up "$(format_rate "$up")" \
    --argjson download_history "$down_json" \
    --argjson upload_history "$up_json" \
    '{interface:$interface,connection:$connection,status:$status,local_ip:$local_ip,gateway:$gateway,down:$down,up:$up,download_history:$download_history,upload_history:$upload_history}'
}

print_system_log() {
  local fallback

  if command -v journalctl >/dev/null 2>&1; then
    if journalctl -n 8 --no-pager -o short-iso >/dev/null 2>&1; then
      journalctl -n 8 --no-pager -o short-iso 2>/dev/null \
        | tail -n 8 \
        | awk '
            {
              timestamp=$1
              sub(/^.*T/, "", timestamp)
              sub(/\+.*/, "", timestamp)
              $1=""
              $2=""
              sub(/^  */, "", $0)
              print "[" timestamp "] " $0
            }
          ' \
        | trim_line 78 \
        | json_lines
      return 0
    fi
  fi

  fallback=$'[12:45:10] systemd[1]: Started Session 3 of user nih.\n[12:45:10] kdeinit5[733]: Starting KDE Plasma\n[12:45:11] kwin_wayland[1021]: Compositor started\n[12:45:12] NetworkManager[620]: Network is online\n[12:45:13] systemd[1]: Reached target Graphical Interface\n[12:45:14] keskos[1]: Hud interface initialized\n[12:45:15] keskos[1]: All systems operational\n[12:45:16] keskos[1]: Awaiting input...'
  printf '%s\n' "$fallback" | json_lines
}

print_system_profile() {
  local host_name user_name machine_name session_name uptime_text

  host_name="$(hostname 2>/dev/null || printf 'kesk-node-01')"
  user_name="$(id -un 2>/dev/null || printf '%s' "${USER:-user}")"
  machine_name="$(uname -m 2>/dev/null || printf 'unknown')"
  session_name="$(pretty_session)"
  uptime_text="$(uptime -p 2>/dev/null | sed 's/^up //')"

  jq -nc \
    --arg host "$host_name" \
    --arg user "$user_name" \
    --arg machine "$machine_name" \
    --arg session "$session_name" \
    --arg uptime "${uptime_text:-n/a}" \
    --arg node "KESK-01" \
    --arg access "GRANTED" \
    --arg clearance "USER" \
    '{host:$host,user:$user,machine:$machine,session:$session,uptime:$uptime,node:$node,access:$access,clearance:$clearance}'
}

print_memory() {
  local total_kib available_kib used_kib percent segments_filled

  total_kib="$(awk '/MemTotal:/ { print $2; exit }' /proc/meminfo 2>/dev/null || printf '0')"
  available_kib="$(awk '/MemAvailable:/ { print $2; exit }' /proc/meminfo 2>/dev/null || printf '0')"
  used_kib=$(( total_kib - available_kib ))

  if (( total_kib > 0 )); then
    percent=$(( used_kib * 100 / total_kib ))
  else
    percent=0
  fi

  segments_filled=$(( (percent * 28 + 99) / 100 ))
  if (( segments_filled > 28 )); then
    segments_filled=28
  fi

  jq -nc \
    --arg total "$(format_kib "$total_kib")" \
    --arg used "$(format_kib "$used_kib")" \
    --arg free "$(format_kib "$available_kib")" \
    --arg percent "${percent}%" \
    --argjson percent_value "$percent" \
    --argjson segments_filled "$segments_filled" \
    '{total:$total,used:$used,free:$free,percent:$percent,percent_value:$percent_value,segments_filled:$segments_filled}'
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

  chmod +x "$HOME/.local/bin/keskos-quickshell-data"
}

install_quickshell_config() {
  mkdir -p "$HOME/.config/quickshell/widgets" "$HOME/.local/bin"

  backup_file "$HOME/.config/quickshell/main.qml"
  install -m 644 \
    "$REPO_DIR/configs/quickshell/main.qml" \
    "$HOME/.config/quickshell/main.qml"

  for widget_file in "$REPO_DIR"/configs/quickshell/widgets/*.qml; do
    backup_file "$HOME/.config/quickshell/widgets/$(basename "$widget_file")"
    install -m 644 \
      "$widget_file" \
      "$HOME/.config/quickshell/widgets/$(basename "$widget_file")"
  done

  install -m 755 \
    "$REPO_DIR/scripts/start-quickshell.sh" \
    "$HOME/.local/bin/keskos-start-quickshell"

  install -m 755 \
    "$REPO_DIR/scripts/select-resolution.sh" \
    "$HOME/.local/bin/keskos-select-resolution"
}

cleanup_old_widget_state() {
  rm -rf "$HOME/.config/eww"
  rm -f "$HOME/.config/autostart/keskos-eww.desktop"
  rm -f "$HOME/.local/bin/keskos-start-eww"
  rm -f "$HOME/.local/bin/keskos-eww-data"
  pkill -x eww >/dev/null 2>&1 || true
}

build_quickshell_from_source() {
  local src_dir="$HOME/.cache/keskos/quickshell-src"

  if command -v quickshell >/dev/null 2>&1 && [[ "${KESKOS_REBUILD_QUICKSHELL:-0}" != "1" ]]; then
    log "Keeping the existing system quickshell binary at $(command -v quickshell)."
    return 0
  fi

  if [[ -x "$HOME/.local/bin/quickshell" && "${KESKOS_REBUILD_QUICKSHELL:-0}" != "1" ]]; then
    log "Keeping the existing local quickshell binary at $HOME/.local/bin/quickshell."
    return 0
  fi

  rm -rf "$src_dir"

  log "Cloning quickshell ${QUICKSHELL_REF} from the official repository..."
  git clone --branch "$QUICKSHELL_REF" --depth 1 https://git.outfoxxed.me/outfoxxed/quickshell "$src_dir"

  log "Building quickshell with minimal Wayland layershell support..."
  cmake -GNinja -S "$src_dir" -B "$src_dir/build" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="$HOME/.local" \
    -DDISTRIBUTOR="keskos" \
    -DCRASH_HANDLER=OFF \
    -DUSE_JEMALLOC=OFF \
    -DWAYLAND=ON \
    -DWAYLAND_WLR_LAYERSHELL=ON \
    -DWAYLAND_SESSION_LOCK=OFF \
    -DWAYLAND_TOPLEVEL_MANAGEMENT=OFF \
    -DSCREENCOPY=OFF \
    -DX11=OFF \
    -DSERVICE_PIPEWIRE=OFF \
    -DSERVICE_STATUS_NOTIFIER=OFF \
    -DSERVICE_MPRIS=OFF \
    -DSERVICE_PAM=OFF \
    -DSERVICE_POLKIT=OFF \
    -DHYPRLAND=OFF \
    -DI3=OFF >/dev/null

  cmake --build "$src_dir/build"
  cmake --install "$src_dir/build"
  log "Installed quickshell to $HOME/.local/bin/quickshell."
}

main() {
  install_quickshell_dependencies
  install_quickshell_config
  write_data_helper
  cleanup_old_widget_state
  build_quickshell_from_source
  log "Installed the Quickshell HUD configuration and startup helpers."
}

main "$@"
