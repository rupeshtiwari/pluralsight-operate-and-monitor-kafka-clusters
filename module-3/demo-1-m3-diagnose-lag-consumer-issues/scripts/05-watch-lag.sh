#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/00-env.sh"

REFRESH_SEC="${REFRESH_SEC:-2}"
LOG="/tmp/m3_demo1_consumer.log"

BOLD="\033[1m"; RESET="\033[0m"; DIM="\033[2m"
GREEN="\033[32m"; YELLOW="\033[33m"; RED="\033[31m"; CYAN="\033[36m"

hr() { printf "%s\n" "--------------------------------------------------------------------------------"; }
hide_cursor() { printf "\033[?25l"; }
show_cursor() { printf "\033[?25h"; }
trap show_cursor EXIT

fetch() {
  docker exec broker1 bash -lc "
    env -u JMX_PORT -u KAFKA_JMX_PORT -u KAFKA_JMX_OPTS -u KAFKA_OPTS -u JAVA_TOOL_OPTIONS \
      kafka-consumer-groups --bootstrap-server '$BOOTSTRAP' --group '$GROUP' --describe 2>&1 || true
  "
}

render() {
  local raw rows
  raw="$(fetch)"

  printf "\033[H\033[J"
  echo
  echo -e "${CYAN}${BOLD}Consumer Lag${RESET} ${DIM}(group=${GROUP}, topic=${TOPIC}, refresh=${REFRESH_SEC}s)${RESET}"
  hr
  printf "${BOLD}%-24s %-10s %-14s %-14s %-10s${RESET}\n" "TOPIC" "PARTITION" "CURRENT" "LOG_END" "LAG"
  hr

  if echo "$raw" | grep -qiE "not found|does not exist"; then
    echo -e "${YELLOW}${BOLD}Group not found yet.${RESET}"
    echo -e "${DIM}Start consumer first:${RESET} ./start-consumer.sh"
    hr
    return 0
  fi

  rows="$(
    echo "$raw" | awk -v g="$GROUP" -v t="$TOPIC" '
      $1==g && $2==t && $3 ~ /^[0-9]+$/ { print $2, $3, $4, $5, $6 }
    '
  )"

  if [[ -z "${rows// /}" ]]; then
    echo -e "${YELLOW}${BOLD}No offset rows yet.${RESET}"
    echo -e "${DIM}Tip:${RESET} docker exec broker1 bash -lc \"tail -n 20 $LOG\""
    hr
    return 0
  fi

  echo "$rows" | while read -r topic partition cur end lag; do
    lag_color="$DIM"
    if [[ "$lag" =~ ^[0-9]+$ ]]; then
      if (( lag == 0 )); then lag_color="$GREEN"
      elif (( lag < 5000 )); then lag_color="$YELLOW"
      else lag_color="$RED"
      fi
    fi
    printf "%-24s %-10s %-14s %-14s ${lag_color}%-10s${RESET}\n" \
      "$topic" "$partition" "$cur" "$end" "$lag"
  done
  hr
}

hide_cursor
while true; do
  render
  sleep "$REFRESH_SEC"
done
