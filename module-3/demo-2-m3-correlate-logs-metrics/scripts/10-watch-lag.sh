#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/00-env.sh"

REFRESH_SEC="${REFRESH_SEC:-2}"

# ANSI styles
BOLD="\033[1m"; RESET="\033[0m"; DIM="\033[2m"
GREEN="\033[32m"; YELLOW="\033[33m"; RED="\033[31m"; CYAN="\033[36m"

hr() { printf "%s\n" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; }
hide_cursor() { printf "\033[?25l"; }
show_cursor() { printf "\033[?25h"; }
trap show_cursor EXIT

fetch() {
  docker exec broker1 bash -lc "
    env -u JMX_PORT -u KAFKA_JMX_PORT -u KAFKA_JMX_OPTS -u KAFKA_OPTS -u JAVA_TOOL_OPTIONS \
      kafka-consumer-groups \
        --bootstrap-server '$BOOTSTRAP_SERVERS' \
        --group '$GROUP_ID' \
        --describe 2>/dev/null || true
  "
}

render() {
  local raw rows
  raw="$(fetch)"

  printf "\033[H\033[J"
  echo
  echo -e "${CYAN}${BOLD}🔍 Consumer Lag View${RESET} ${DIM}(group=$GROUP_ID refresh=${REFRESH_SEC}s)${RESET}"
  hr
  printf "${BOLD}%-22s %-6s %-12s %-12s %-8s${RESET}\n" "TOPIC" "PART" "CURRENT" "LOG_END" "LAG"
  hr

  if echo "$raw" | grep -qiE "not found|does not exist"; then
    echo -e "${YELLOW}${BOLD}⚠️  Consumer group not found.${RESET}"
    echo -e "${DIM}💡 Start consumer:${RESET} ./scripts/03-start-consumer.sh"
    hr
    return
  fi

  rows="$(echo "$raw" | awk '
    NR>1 && $6 ~ /^[0-9]+$/ {
      printf "%s %s %s %s %s\n", $2, $3, $4, $5, $6
    }
  ')"

  if [[ -z "${rows// /}" ]]; then
    echo -e "${YELLOW}${BOLD}⚠️  No lag data yet.${RESET}"
    hr
    return
  fi

  echo "$rows" | while read -r topic part cur end lag; do
    if (( lag == 0 )); then
      color="$GREEN"
    elif (( lag < 5000 )); then
      color="$YELLOW"
    else
      color="$RED"
    fi

    printf "%-22s %-6s %-12s %-12s ${color}%-8s${RESET}\n" \
      "$topic" "$part" "$cur" "$end" "$lag"
  done

  hr
  echo -e "${DIM}🧠 Teaching:${RESET} Flat CURRENT + rising LAG = recovery required"
}

hide_cursor
while true; do
  render
  sleep "$REFRESH_SEC"
done
