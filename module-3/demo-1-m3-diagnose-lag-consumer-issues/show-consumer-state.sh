#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/00-env.sh" ]]; then
  # shellcheck disable=SC1091
  source "$SCRIPT_DIR/00-env.sh"
fi

BROKER_CONTAINER="${BROKER_CONTAINER:-broker1}"
BOOTSTRAP_SERVER="${BOOTSTRAP_SERVER:-broker1:9092}"
GROUP_ID="${GROUP_ID:-m3-demo1-diagnose-group}"
TOPIC_NAME="${TOPIC_NAME:-m3-demo1-lag-topic}"
REFRESH_SECONDS="${REFRESH_SECONDS:-2}"

# ANSI
C_RESET=$'\033[0m'
C_BOLD=$'\033[1m'
C_DIM=$'\033[2m'
C_CYAN=$'\033[36m'
C_GREEN=$'\033[32m'
C_YELLOW=$'\033[33m'
C_RED=$'\033[31m'
C_GRAY=$'\033[90m'

color_lag() {
  local v="${1:-0}"
  if [[ ! "$v" =~ ^[0-9]+$ ]]; then
    printf "%s-%s" "$C_GRAY" "$C_RESET"
    return
  fi
  if (( v == 0 )); then
    printf "%s%s%s" "$C_GREEN" "$v" "$C_RESET"
  elif (( v < 5000 )); then
    printf "%s%s%s" "$C_YELLOW" "$v" "$C_RESET"
  else
    printf "%s%s%s" "$C_RED" "$v" "$C_RESET"
  fi
}

render_once() {
  local out
  out="$(docker exec "$BROKER_CONTAINER" bash -lc \
    "kafka-consumer-groups --bootstrap-server '$BOOTSTRAP_SERVER' --describe --group '$GROUP_ID' 2>&1" \
    || true)"

  printf "%sConsumer Group State%s\n" "$C_CYAN" "$C_RESET"
  printf "Group: %s  Topic: %s\n" "$GROUP_ID" "$TOPIC_NAME"
  printf "%sThis proves:%s group exists, partitions assigned, offsets advancing\n\n" "$C_DIM" "$C_RESET"

  if [[ -z "$out" ]] || echo "$out" | grep -qiE "does not exist|not found|Error"; then
    printf "%sGroup not found%s  (consumer not running or not joined yet)\n" "$C_YELLOW" "$C_RESET"
    printf "Next action: start consumer in T4\n"
    return 0
  fi

  # totals (format: GROUP TOPIC PART CUR LOG_END LAG CONSUMER-ID HOST CLIENT-ID)
  local total_lag parts members
  total_lag="$(echo "$out" | awk -v t="$TOPIC_NAME" 'NR==1{next} $2==t && $6 ~ /^[0-9]+$/ {sum+=$6} END{print sum+0}')"
  parts="$(echo "$out" | awk -v t="$TOPIC_NAME" 'NR==1{next} $2==t {c++} END{print c+0}')"
  members="$(echo "$out" | awk -v t="$TOPIC_NAME" '
    NR==1{next}
    $2==t && $7 != "-" && $7 != "" {m[$7]=1}
    END{print length(m)}
  ')"

  # Members color: 0=red, 1=green, >1=yellow (demo should be 1)
  local mem_col="$C_GREEN"
  if (( member
