#!/usr/bin/env bash

if [[ -n "${KESKOS_UI_LIB_LOADED:-}" ]]; then
  return 0 2>/dev/null || exit 0
fi
KESKOS_UI_LIB_LOADED=1

: "${KESKOS_UI_STYLE:=pretty}"

_ui_init() {
  if [[ -n "${KESKOS_UI_INIT_DONE:-}" ]]; then
    return
  fi
  KESKOS_UI_INIT_DONE=1

  _UI_PRETTY=0
  if [[ -t 1 && -z "${NO_COLOR:-}" && "${TERM:-}" != "dumb" && "${KESKOS_UI_STYLE:-pretty}" != "plain" ]]; then
    _UI_PRETTY=1
  fi

  if [[ "$_UI_PRETTY" -eq 1 ]]; then
    _UI_RESET=$'\033[0m'
    _UI_BOLD=$'\033[1m'
    _UI_DIM=$'\033[2m'
    _UI_ORANGE=$'\033[38;5;208m'
    _UI_ORANGE_SOFT=$'\033[38;5;173m'
    _UI_BLUE=$'\033[38;5;39m'
    _UI_CYAN=$'\033[38;5;45m'
    _UI_YELLOW=$'\033[38;5;221m'
    _UI_GREEN=$'\033[38;5;78m'
    _UI_RED=$'\033[38;5;203m'
    _UI_MAGENTA=$'\033[38;5;213m'
    _UI_GRAY=$'\033[38;5;245m'
  else
    _UI_RESET=""
    _UI_BOLD=""
    _UI_DIM=""
    _UI_ORANGE=""
    _UI_ORANGE_SOFT=""
    _UI_BLUE=""
    _UI_CYAN=""
    _UI_YELLOW=""
    _UI_GREEN=""
    _UI_RED=""
    _UI_MAGENTA=""
    _UI_GRAY=""
  fi
}

ui_is_pretty() {
  _ui_init
  [[ "$_UI_PRETTY" -eq 1 ]]
}

_ui_status_line() {
  local color="$1"
  local prefix="$2"
  shift 2
  local message="$*"

  _ui_init
  if ui_is_pretty; then
    printf '%b::%b [%s] %s\n' "$color" "$_UI_RESET" "$prefix" "$message"
  else
    printf '[%s] %s\n' "$prefix" "$message"
  fi
}

ui_log() {
  local prefix="${1:-keskos}"
  shift || true
  _ui_init
  _ui_status_line "$_UI_CYAN" "$prefix" "$*"
}

ui_info() {
  local prefix="${1:-keskos}"
  shift || true
  _ui_init
  _ui_status_line "$_UI_BLUE" "$prefix" "$*"
}

ui_warn() {
  local prefix="${1:-keskos}"
  shift || true
  _ui_init
  if ui_is_pretty; then
    printf '%b!!%b [%s] %s\n' "$_UI_YELLOW" "$_UI_RESET" "$prefix" "$*" >&2
  else
    printf '[%s] warning: %s\n' "$prefix" "$*" >&2
  fi
}

ui_error() {
  local prefix="${1:-keskos}"
  shift || true
  _ui_init
  if ui_is_pretty; then
    printf '%bxx%b [%s] %s\n' "$_UI_RED" "$_UI_RESET" "$prefix" "$*" >&2
  else
    printf '[%s] error: %s\n' "$prefix" "$*" >&2
  fi
}

ui_success() {
  local prefix="${1:-keskos}"
  shift || true
  _ui_init
  _ui_status_line "$_UI_GREEN" "$prefix" "$*"
}

ui_hr() {
  _ui_init
  if ui_is_pretty; then
    printf '%b+-------------------------------------------------------+%b\n' "$_UI_GRAY" "$_UI_RESET"
  else
    printf '%s\n' '---------------------------------------------------------'
  fi
}

ui_banner() {
  _ui_init
  if ui_is_pretty; then
    printf '%b+-------------------------------------------------------+%b\n' "$_UI_ORANGE" "$_UI_RESET"
    printf '%b|  _  __               __                                |%b\n' "$_UI_ORANGE" "$_UI_RESET"
    printf '%b| | |/ /__  ________  / /_  ____  _____                 |%b\n' "$_UI_ORANGE" "$_UI_RESET"
    printf '%b| |   / _ \\/ ___/ _ \\/ __ \\/ __ \\/ ___/                 |%b\n' "$_UI_ORANGE" "$_UI_RESET"
    printf '%b| |   /  __(__  )  __/ /_/ / /_/ (__  )                 |%b\n' "$_UI_ORANGE" "$_UI_RESET"
    printf '%b| |_|\\_\\___/____/\\___/_.___/\\____/____/                 |%b\n' "$_UI_ORANGE" "$_UI_RESET"
    printf '%b|                                                       |%b\n' "$_UI_ORANGE" "$_UI_RESET"
    printf '%b|        Arch KDE Plasma install and setup flow         |%b\n' "$_UI_ORANGE" "$_UI_RESET"
    printf '%b+-------------------------------------------------------+%b\n' "$_UI_ORANGE" "$_UI_RESET"
  else
    printf '%s\n' 'KESKOS'
    printf '%s\n' 'Arch KDE Plasma install and setup flow'
  fi
}

ui_section() {
  local title="$1"
  _ui_init
  printf '\n'
  if ui_is_pretty; then
    printf '%b== %s ==%b\n' "$_UI_MAGENTA$_UI_BOLD" "$title" "$_UI_RESET"
  else
    printf '== %s ==\n' "$title"
  fi
}

ui_step() {
  local current="$1"
  local total="$2"
  local title="$3"
  _ui_init
  if ui_is_pretty; then
    printf '\n%b[%02d/%02d]%b %b%s%b\n' "$_UI_ORANGE" "$current" "$total" "$_UI_RESET" "$_UI_BOLD" "$title" "$_UI_RESET"
  else
    printf '\n[%02d/%02d] %s\n' "$current" "$total" "$title"
  fi
}

_ui_yes_no_label() {
  local value="$1"
  case "${value,,}" in
    y|yes|true|1) printf 'y' ;;
    *) printf 'n' ;;
  esac
}

_ui_yes_no_display() {
  local value="$1"
  _ui_init
  if [[ "$(_ui_yes_no_label "$value")" == "y" ]]; then
    if ui_is_pretty; then
      printf '%bEnabled%b' "$_UI_GREEN" "$_UI_RESET"
    else
      printf 'Enabled'
    fi
  else
    if ui_is_pretty; then
      printf '%bDisabled%b' "$_UI_GRAY" "$_UI_RESET"
    else
      printf 'Disabled'
    fi
  fi
}

ui_summary_row() {
  local label="$1"
  local value="$2"
  _ui_init
  printf '  %-18s %s\n' "${label}:" "$value"
}

ui_prompt_yes_no() {
  local var_name="$1"
  local default_value="$2"
  local title="$3"
  local subtitle="$4"
  local prompt_suffix=""
  local raw_answer=""
  local normalized_default
  local -n out_ref="$var_name"

  normalized_default="$(_ui_yes_no_label "$default_value")"
  if [[ "$normalized_default" == "y" ]]; then
    prompt_suffix='[Y/n]'
  else
    prompt_suffix='[y/N]'
  fi

  ui_info "keskos" "$title"
  printf '   %s\n' "$subtitle"

  if [[ -n "${out_ref:-}" ]]; then
    raw_answer="${out_ref}"
    ui_info "keskos" "Using preset answer: ${raw_answer}"
  elif [[ ! -t 0 ]]; then
    raw_answer="$normalized_default"
    ui_info "keskos" "Non-interactive session detected. Using default: $normalized_default"
  else
    if ui_is_pretty; then
      printf '   %b=>%b %s ' "$_UI_ORANGE" "$_UI_RESET" "$prompt_suffix"
    else
      printf '   => %s ' "$prompt_suffix"
    fi
    read -r raw_answer
  fi

  case "${raw_answer,,}" in
    y|yes|true|1)
      out_ref="y"
      ;;
    n|no|false|0)
      out_ref="n"
      ;;
    "")
      out_ref="$normalized_default"
      ;;
    *)
      out_ref="$normalized_default"
      ;;
  esac
}
