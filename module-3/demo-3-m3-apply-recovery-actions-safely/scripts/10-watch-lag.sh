#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/00-env.sh"

REFRESH_SEC="${REFRESH_SEC:-2}"
RUN_FOR_SEC="${RUN_FOR_SEC:-0}"   # 0 = forever

BROKER_CONTAINER="${BROKER_CONTAINER:-broker1}"
BOOTSTRAP="${BOOTSTRAP:-${BOOTSTRAP_SERVERS:-broker1:9092}}"
GROUP_ID="${GROUP_ID:-${GROUP:-m3-correlation-cg}}"
TOPIC="${TOPIC:-m3-correlation-topic}"

# ANSI
BOLD=$'\033[1m'; RESET=$'\033[0m'; DIM=$'\033[2m'
GREEN=$'\033[32m'; YELLOW=$'\033[33m'; RED=$'\033[31m'; CYAN=$'\033[36m'

hr(){ printf "%s\n" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; }
hide_cursor(){ printf "\033[?25l"; }
show_cursor(){ printf "\033[?25h"; }
trap show_cursor EXIT

fetch() {
  docker exec "$BROKER_CONTAINER" bash -lc "
    env -u JMX_PORT -u KAFKA_JMX_PORT -u KAFKA_JMX_OPTS -u KAFKA_OPTS -u JAVA_TOOL_OPTIONS \
      kafka-consumer-groups --bootstrap-server '$BOOTSTRAP' --group '$GROUP_ID' --describe 2>/dev/null || true
  "
}

clear_screen() {
  # tmux/xterm friendly
  printf "\033[H\033[2J\033[3J"
}

render() {
  local raw rows
  raw="$(fetch)"

  clear_screen
  printf "\n"
  printf "${CYAN}${BOLD}🔍 Consumer Lag View${RESET} ${DIM}(group=%s topic=%s refresh=%ss)${RESET}\n" "$GROUP_ID" "$TOPIC" "$REFRESH_SEC"
  hr
  printf "${BOLD}%-22s %-6s %-12s %-12s %-8s${RESET}\n" "TOPIC" "PART" "CURRENT" "LOG_END" "LAG"
  hr

  if echo "$raw" | grep -qiE "not found|does not exist"; then
    printf "${YELLOW}${BOLD}⚠️  Consumer group not found.${RESET}\n"
    printf "${DIM}💡 Start consumer:${RESET} ./scripts/03-start-consumer.sh\n"
    hr
    return
  fi

  # Filter to only the topic we care about
  rows="$(echo "$raw" | awk -v topic="$TOPIC" '
    NR>1 && $2==topic && $6 ~ /^[0-9]+$/ { printf "%s %s %s %s %s\n", $2, $3, $4, $5, $6 }
  ')"

  if [[ -z "${rows// /}" ]]; then
    printf "${YELLOW}${BOLD}⚠️  No lag data yet for topic '%s'.${RESET}\n" "$TOPIC"
    hr
    return
  fi

  while read -r topic part cur end lag; do
    local color="$RED"
    if (( lag == 0 )); then color="$GREEN"
    elif (( lag < 5000 )); then color="$YELLOW"
    fi

    printf "%-22s %-6s %-12s %-12s ${color}%-8s${RESET}\n" \
      "$topic" "$part" "$cur" "$end" "$lag"
  done <<< "$rows"

  hr
  printf "${DIM}🧠 Teaching:${RESET} CURRENT stuck + LOG_END rising = consumer stalled.\n"
}

hide_cursor
start_ts=$SECONDS
while true; do
  render
  if (( RUN_FOR_SEC > 0 )) && (( SECONDS - start_ts >= RUN_FOR_SEC )); then
    break
  fi
  sleep "$REFRESH_SEC"
done
