#!/usr/bin/env bash
set -euo pipefail

SCRIPT_SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_SOURCE_DIR/lib-ui.sh" ]]; then
  # shellcheck source=scripts/lib-ui.sh
  . "$SCRIPT_SOURCE_DIR/lib-ui.sh"
fi

log() {
  if declare -F ui_log >/dev/null 2>&1; then
    ui_log "setup-branding" "$1"
  else
    printf '[setup-branding] %s\n' "$1"
  fi
}

warn() {
  if declare -F ui_warn >/dev/null 2>&1; then
    ui_warn "setup-branding" "$1"
  else
    printf '[setup-branding] warning: %s\n' "$1" >&2
  fi
}

fail() {
  if declare -F ui_error >/dev/null 2>&1; then
    ui_error "setup-branding" "$1"
  else
    printf '[setup-branding] error: %s\n' "$1" >&2
  fi
  exit 1
}

require_sudo() {
  if ! command -v sudo >/dev/null 2>&1; then
    fail "sudo is required to apply system branding."
  fi
}

backup_system_file() {
  local file_path="$1"
  local backup_path="${file_path}.keskos.bak"

  if sudo test -e "$file_path" && ! sudo test -e "$backup_path"; then
    sudo cp -a "$file_path" "$backup_path"
  fi
}

write_os_release() {
  local source_file="/usr/lib/os-release"
  local temp_file
  temp_file="$(mktemp)"

  if [[ ! -r "$source_file" ]]; then
    source_file="/etc/os-release"
  fi

  [[ -r "$source_file" ]] || fail "Could not read an existing os-release file."

  python3 - "$source_file" "$temp_file" <<'PY'
from pathlib import Path
import sys

source_path = Path(sys.argv[1])
target_path = Path(sys.argv[2])

lines = source_path.read_text(encoding="utf-8").splitlines()
output = []
seen_name = False
seen_pretty = False
seen_variant = False
seen_variant_id = False

for line in lines:
    if line.startswith("NAME="):
        output.append('NAME="Kesk OS"')
        seen_name = True
    elif line.startswith("PRETTY_NAME="):
        output.append('PRETTY_NAME="Kesk OS"')
        seen_pretty = True
    elif line.startswith("VARIANT="):
        output.append('VARIANT="Kesk OS"')
        seen_variant = True
    elif line.startswith("VARIANT_ID="):
        output.append("VARIANT_ID=keskos")
        seen_variant_id = True
    else:
        output.append(line)

if not seen_name:
    output.append('NAME="Kesk OS"')
if not seen_pretty:
    output.append('PRETTY_NAME="Kesk OS"')
if not seen_variant:
    output.append('VARIANT="Kesk OS"')
if not seen_variant_id:
    output.append("VARIANT_ID=keskos")

target_path.write_text("\n".join(output) + "\n", encoding="utf-8")
PY

  backup_system_file "/etc/os-release"
  sudo rm -f /etc/os-release
  sudo install -m 644 "$temp_file" /etc/os-release
  rm -f "$temp_file"
}

write_lsb_release() {
  local temp_file
  local release_name="rolling"
  temp_file="$(mktemp)"

  if [[ -r /usr/lib/os-release ]]; then
    # shellcheck disable=SC1091
    . /usr/lib/os-release
  elif [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
  fi

  if [[ -n "${VERSION_ID:-}" ]]; then
    release_name="${VERSION_ID}"
  fi

  cat >"$temp_file" <<EOF
DISTRIB_ID=KeskOS
DISTRIB_RELEASE=${release_name}
DISTRIB_DESCRIPTION="Kesk OS"
EOF

  backup_system_file "/etc/lsb-release"
  sudo install -m 644 "$temp_file" /etc/lsb-release
  rm -f "$temp_file"
}

main() {
  require_sudo
  write_os_release
  write_lsb_release
  log "Applied the optional Kesk OS system branding. Apps that read /etc/os-release should now report Kesk OS."
  warn "Backups were saved as /etc/os-release.keskos.bak and /etc/lsb-release.keskos.bak when those files already existed."
}

main "$@"
