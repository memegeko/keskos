#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${1:?usage: setup-scanlines.sh /path/to/repo}"

log() {
  printf '[setup-scanlines] %s\n' "$1"
}

mkdir -p "$HOME/.config/picom"

install -m 644 \
  "$REPO_DIR/configs/picom/picom.conf" \
  "$HOME/.config/picom/picom.conf"

log "Installed lightweight picom configuration. Scanlines and noise are baked into the wallpaper."
