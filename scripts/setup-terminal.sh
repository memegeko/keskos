#!/usr/bin/env bash
set -euo pipefail

SCRIPT_SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_SOURCE_DIR/lib-ui.sh" ]]; then
  # shellcheck source=scripts/lib-ui.sh
  . "$SCRIPT_SOURCE_DIR/lib-ui.sh"
fi

REPO_DIR="${1:?usage: setup-terminal.sh /path/to/repo}"

log() {
  if declare -F ui_log >/dev/null 2>&1; then
    ui_log "setup-terminal" "$1"
  else
    printf '[setup-terminal] %s\n' "$1"
  fi
}

warn() {
  if declare -F ui_warn >/dev/null 2>&1; then
    ui_warn "setup-terminal" "$1"
  else
    printf '[setup-terminal] warning: %s\n' "$1" >&2
  fi
}

kwriteconfig_bin=""
if command -v kwriteconfig6 >/dev/null 2>&1; then
  kwriteconfig_bin="kwriteconfig6"
elif command -v kwriteconfig5 >/dev/null 2>&1; then
  kwriteconfig_bin="kwriteconfig5"
fi

backup_file() {
  local file_path="$1"

  if [[ -f "$file_path" && ! -f "${file_path}.keskos.bak" ]]; then
    cp "$file_path" "${file_path}.keskos.bak"
  fi
}

install_terminal_shell() {
  local shell_path="$HOME/.local/bin/keskos-terminal-shell"

  cat >"$shell_path" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

shell_bin="${SHELL:-/bin/bash}"
fastfetch_config="$HOME/.config/fastfetch/config.jsonc"
bash_rc_override="$HOME/.config/keskos/bashrc"
if [[ ! -x "$shell_bin" ]]; then
  shell_bin="/bin/bash"
fi

if [[ -t 1 && -z "${KESKOS_FASTFETCH_SHOWN:-}" ]]; then
  export KESKOS_FASTFETCH_SHOWN=1
  if command -v fastfetch >/dev/null 2>&1; then
    if [[ -f "$fastfetch_config" ]]; then
      fastfetch --config "$fastfetch_config" || true
    else
      fastfetch || true
    fi
    printf '\n'
  fi
fi

case "$(basename "$shell_bin")" in
  bash)
    if [[ -f "$bash_rc_override" ]]; then
      exec "$shell_bin" --rcfile "$bash_rc_override" -i
    fi
    exec "$shell_bin" -l
    ;;
  nu|nushell)
    exec "$shell_bin" --login
    ;;
  sh|dash|zsh|fish|ksh|mksh)
    exec "$shell_bin" -l
    ;;
  *)
    exec "$shell_bin"
    ;;
esac
EOF

  chmod +x "$shell_path"
}

install_shell_overrides() {
  local bash_rc_path="$HOME/.config/keskos/bashrc"

  backup_file "$bash_rc_path"

  mkdir -p "$HOME/.config/keskos"

  cat >"$bash_rc_path" <<'EOF'
# KeskOS Bash prompt overlay

if [[ -r /etc/bash.bashrc ]]; then
  # shellcheck disable=SC1091
  . /etc/bash.bashrc
fi

if [[ -r "$HOME/.bashrc" ]]; then
  # shellcheck disable=SC1090
  . "$HOME/.bashrc"
fi

export HOSTNAME="keskos"
PS1='\[\e[38;2;206;106;53m\]keskos :: \W > \[\e[0m\]'
EOF
}

install_fastfetch_assets() {
  backup_file "$HOME/.config/fastfetch/config.jsonc"
  backup_file "$HOME/.config/fastfetch/logo.txt"

  mkdir -p "$HOME/.config/fastfetch"

  install -m 644 \
    "$REPO_DIR/configs/fastfetch/config.jsonc" \
    "$HOME/.config/fastfetch/config.jsonc"

  python3 - "$REPO_DIR/configs/fastfetch/logo.txt" "$HOME/.config/fastfetch/logo.txt" <<'PY'
from pathlib import Path
import sys

source_path = Path(sys.argv[1])
target_path = Path(sys.argv[2])

mapping = {
    "*": "$1*",
    "=": "$2=",
    "+": "$3+",
}

content = source_path.read_text(encoding="utf-8")
target_path.write_text("".join(mapping.get(ch, ch) for ch in content), encoding="utf-8")
PY
}

install_konsole_assets() {
  backup_file "$HOME/.local/share/konsole/KeskOS.colorscheme"
  backup_file "$HOME/.local/share/konsole/KeskOS.profile"

  mkdir -p "$HOME/.local/share/konsole"

  install -m 644 \
    "$REPO_DIR/configs/konsole/KeskOS.colorscheme" \
    "$HOME/.local/share/konsole/KeskOS.colorscheme"

  install -m 644 \
    "$REPO_DIR/configs/konsole/KeskOS.profile" \
    "$HOME/.local/share/konsole/KeskOS.profile"
}

apply_konsole_profile() {
  local profile_path="$HOME/.local/share/konsole/KeskOS.profile"
  local shell_path="$HOME/.local/bin/keskos-terminal-shell"

  backup_file "$HOME/.config/konsolerc"

  if [[ -n "$kwriteconfig_bin" ]]; then
    "$kwriteconfig_bin" \
      --file "$profile_path" \
      --group General \
      --key Command \
      "$shell_path"

    "$kwriteconfig_bin" \
      --file "$profile_path" \
      --group Appearance \
      --key ColorScheme \
      "KeskOS"

    "$kwriteconfig_bin" \
      --file "$profile_path" \
      --group Appearance \
      --key Font \
      "JetBrainsMono Nerd Font,11,-1,5,50,0,0,0,0,0"

    "$kwriteconfig_bin" \
      --file "$HOME/.config/konsolerc" \
      --group "Desktop Entry" \
      --key DefaultProfile \
      "KeskOS.profile"

    return
  fi

  warn "kwriteconfig was not found. Konsole assets were installed, but the default profile may need to be selected manually."
}

main() {
  mkdir -p "$HOME/.local/bin" "$HOME/.local/share/konsole" "$HOME/.config" "$HOME/.config/fastfetch" "$HOME/.config/keskos"

  install_terminal_shell
  install_shell_overrides
  install_fastfetch_assets
  install_konsole_assets
  apply_konsole_profile

  log "Installed the KeskOS Konsole profile, fastfetch theme, color scheme, and terminal wrapper."
}

main "$@"
