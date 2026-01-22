#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/00-env.sh"

REFRESH_SEC="${REFRESH_SEC:-2}"
LOG="${CONSUMER_LOG:-/tmp/ops-demo-consumer.log}"

BOLD="\033[1m"; RESET="\033[0m"; DIM="\033[2m"
GREEN="\033[32m"; YELLOW="\033[33m"; RED="\033[31m"; CYAN="\033[36m"

hr() { printf "%s\n" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; }
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

  printf "\033[H\033[J"   # Clear screen
  echo
  echo -e "${CYAN}${BOLD}🔍 Lag + ISR Snapshot${RESET} ${DIM}(group=$GROUP topic=$TOPIC refresh=${REFRESH_SEC}s)${RESET}"
  hr
  printf "${BOLD}%-20s %-8s %-12s %-12s %-8s${RESET}\n" "TOPIC" "PART" "CURR" "LOG_END" "LAG 🐢"
  hr

  if echo "$raw" | grep -qiE "not found|does not exist"; then
    echo -e "${YELLOW}${BOLD}⚠️  Consumer group not found yet.${RESET}"
    echo -e "${DIM}💡 Hint:${RESET} Run: ./scripts/03-start-consumer.sh"
    hr
    return 0
  fi

  rows="$(echo "$raw" | awk -v g="$GROUP" -v t="$TOPIC" '$1==g && $2==t && $3 ~ /^[0-9]+$/ { print $2, $3, $4, $5, $6 }')"

  if [[ -z "${rows// /}" ]]; then
    echo -e "${YELLOW}${BOLD}⚠️  No offset rows yet.${RESET}"
    echo -e "${DIM}💡 Hint:${RESET} docker exec broker1 bash -lc \"tail -n 20 '$LOG'\""
    hr
    return 0
  fi

  echo "$rows" | while read -r topic part cur end lag; do
    lag_color="$DIM"
    if [[ "$lag" =~ ^[0-9]+$ ]]; then
      if (( lag == 0 )); then lag_color="$GREEN"      # ✅ No lag
      elif (( lag < 5000 )); then lag_color="$YELLOW" # ⚠️ Moderate lag
      else lag_color="$RED"                            # 🔥 High lag
      fi
    fi

    # 🎯 Output decorated row
    printf "%-20s %-8s %-12s %-12s ${lag_color}%-8s${RESET}\n" "$topic" "$part" "$cur" "$end" "$lag"
  done

  hr
  echo -e "${DIM}🧠 Narration Tip:${RESET} LAG = LOG_END - CURRENT | High lag 🔥 could mean ISR shrink or consumer delay"
}

hide_cursor
while true; do
  render
  sleep "$REFRESH_SEC"
done
