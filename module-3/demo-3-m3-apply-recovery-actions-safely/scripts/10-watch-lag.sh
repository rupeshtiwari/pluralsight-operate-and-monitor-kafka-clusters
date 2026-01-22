#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/00-env.sh"

REFRESH_SEC="${REFRESH_SEC:-2}"

# Use *real* escape characters so colors work with both echo and printf.
BOLD=$'\033[1m'; RESET=$'\033[0m'; DIM=$'\033[2m'
GREEN=$'\033[32m'; YELLOW=$'\033[33m'; RED=$'\033[31m'; CYAN=$'\033[36m'

hr() { printf "%s\n" "--------------------------------------------------------------------------------"; }
hide_cursor() { printf "\033[?25l"; }
show_cursor() { printf "\033[?25h"; }
trap show_cursor EXIT

fetch_raw() {
  docker exec "$BROKER_CONTAINER" bash -lc "
    env -u JMX_PORT -u KAFKA_JMX_PORT -u KAFKA_JMX_OPTS -u KAFKA_OPTS -u JAVA_TOOL_OPTIONS \
      kafka-consumer-groups --bootstrap-server '$BOOTSTRAP' --group '$GROUP' --describe 2>&1 || true
  "
}

render() {
  local raw rows
  raw="$(fetch_raw)"

  # Clear screen + keep a single table (prevents stacked output on recording).
  printf '%b' $'\033[H\033[J'
  echo
  printf '%b\n' "${CYAN}${BOLD}Lag Snapshot${RESET} ${DIM}group=${GROUP}  topic=${TOPIC}  refresh=${REFRESH_SEC}s${RESET}"
  hr
  printf "${BOLD}%-22s %-10s %-12s %-12s %-10s${RESET}\n" "TOPIC" "PARTITION" "CURRENT" "LOG_END" "LAG"
  hr

  if echo "$raw" | grep -qiE "not found|does not exist"; then
    printf '%b\n' "${YELLOW}${BOLD}Consumer group not found yet.${RESET}"
    printf '%b\n' "${DIM}Run: ${RESET}./scripts/03-start-consumer.sh"
    hr
    return 0
  fi

  rows="$(
    echo "$raw" | awk -v g="$GROUP" -v t="$TOPIC" '$1==g && $2==t && $3 ~ /^[0-9]+$/ { print $2, $3, $4, $5, $6 }'
  )"

  if [[ -z "${rows// /}" ]]; then
    printf '%b\n' "${YELLOW}${BOLD}No offset rows yet.${RESET}"
    printf '%b\n' "${DIM}Tip:${RESET} docker exec $BROKER_CONTAINER tail -n 30 $CONSUMER_LOG"
    hr
    return 0
  fi

  echo "$rows" | while read -r topic partition cur end lag; do
    local lag_color="$DIM"
    if [[ "$lag" =~ ^[0-9]+$ ]]; then
      if (( lag == 0 )); then lag_color="$GREEN";
      elif (( lag < 5000 )); then lag_color="$YELLOW";
      else lag_color="$RED";
      fi
    fi
    # Use %b so the color sequences are interpreted correctly.
    printf "%-22s %-10s %-12s %-12s %b%-10s%b\n" "$topic" "$partition" "$cur" "$end" "$lag_color" "$lag" "$RESET"
  done
  hr
}

hide_cursor
while true; do
  render
  sleep "$REFRESH_SEC"
done
