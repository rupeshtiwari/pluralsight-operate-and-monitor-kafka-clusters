#!/usr/bin/env bash
# UI helpers for demo scripts (macOS bash 3.2 safe)

set -e

# Colors (ANSI)
RESET="\033[0m"
BOLD="\033[1m"
DIM="\033[2m"

CYAN="\033[36m"
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
MAGENTA="\033[35m"

HR_CHAR="─"

# Compatibility colors used by older scripts
BLUE="${BLUE:-$CYAN}"   # older scripts expect BLUE


hr() {
  local cols
  cols="$(tput cols 2>/dev/null || echo 80)"
  printf "%*s\n" "$cols" "" | tr " " "$HR_CHAR"
}

title() {
  local text="$1"
  printf "\n${BOLD}%s${RESET}\n" "$text"
  hr
}

kv() {
  local k="$1"
  local v="$2"
  printf "%-18s %s\n" "${k}:" "$v"
}

info()  { printf "${CYAN}%s${RESET}\n" "$1"; }
ok()    { printf "${GREEN}[OK]${RESET} %s\n" "$1"; }
warn()  { printf "${YELLOW}[WARN]${RESET} %s\n" "$1"; }
err()   { printf "${RED}[ERR]${RESET} %s\n" "$1" >&2; }

# Colorize a numeric lag value (string safe)
lag_color() {
  # args: lag warn_threshold crit_threshold
  local lag="${1:-0}"
  local warn_thr="${2:-100}"
  local crit_thr="${3:-1000}"

  # non-numeric -> print as-is
  case "$lag" in
    ''|*[!0-9]*) printf "%s" "$lag"; return 0 ;;
  esac

  if [ "$lag" -ge "$crit_thr" ]; then
    printf "${RED}%s${RESET}" "$lag"
  elif [ "$lag" -ge "$warn_thr" ]; then
    printf "${YELLOW}%s${RESET}" "$lag"
  else
    printf "${GREEN}%s${RESET}" "$lag"
  fi
}

# Simple table header helper
table_header() {
  # prints header row + divider
  local header="$1"
  printf "${BOLD}%s${RESET}\n" "$header"
  hr
}
 


# Tag line (compact, clean)
ui_tag() {
  # usage: ui_tag "Label"
  local label="$1"
  printf "${DIM}${label}${RESET}\n"
}

# Backward-compatible aliases (older scripts)
ui_h1()   { title "$1"; }
ui_kv()   { kv "$1" "$2"; }
ui_ok()   { ok "$1"; }
ui_warn() { warn "$1"; }
ui_err()  { err "$1"; }
