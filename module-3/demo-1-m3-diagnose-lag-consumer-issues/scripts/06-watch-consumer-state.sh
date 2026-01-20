# scripts/06-watch-consumer-state.sh
#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/00-env.sh"

REFRESH_SEC="${REFRESH_SEC:-2}"
LOG="/tmp/m3_demo1_consumer.log"

BOLD="\033[1m"; RESET="\033[0m"; DIM="\033[2m"
GREEN="\033[32m"; YELLOW="\033[33m"; RED="\033[31m"; CYAN="\033[36m"; MAGENTA="\033[35m"

hr() { printf "%s\n" "--------------------------------------------------------------------------------"; }
hide_cursor() { printf "\033[?25l"; }
show_cursor() { printf "\033[?25h"; }
trap show_cursor EXIT

fetch() {
  # Never allow a fetch failure to kill the watcher
  docker exec broker1 bash -lc "
    env -u JMX_PORT -u KAFKA_JMX_PORT -u KAFKA_JMX_OPTS -u KAFKA_OPTS -u JAVA_TOOL_OPTIONS \
      kafka-consumer-groups --bootstrap-server '$BOOTSTRAP' --group '$GROUP' --describe 2>&1 || true
  " || true
}

render() {
  local raw rows members partitions total_lag
  raw="$(fetch)"

  # Clear + redraw (same as T1)
  printf "\033[H\033[J"
  echo
  echo -e "${CYAN}${BOLD}Consumer Group State${RESET} ${DIM}(refresh=${REFRESH_SEC}s)${RESET}"
  echo -e "${DIM}Group:${RESET} ${BOLD}${GROUP}${RESET}   ${DIM}Topic:${RESET} ${BOLD}${TOPIC}${RESET}"
  hr

  if echo "$raw" | grep -qiE "not found|does not exist"; then
    echo -e "${YELLOW}${BOLD}Group not found yet.${RESET}"
    echo -e "${DIM}Next:${RESET} run ./scripts/04-start-consumer.sh --prime then ./scripts/04-start-consumer.sh"
    hr
    return 0
  fi

  # Pull topic rows (topic, partition, current, log_end, lag)
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

  partitions="$(echo "$rows" | wc -l | tr -d ' ')"
  # Members: count distinct consumer-id from the raw output (last column)
  members="$(
    echo "$raw" | awk -v g="$GROUP" -v t="$TOPIC" '
      $1==g && $2==t && $3 ~ /^[0-9]+$/ && $NF!="" { print $NF }
    ' | sort -u | wc -l | tr -d " "
  )"

  total_lag="$(
    echo "$rows" | awk '{sum+=$5} END{print sum+0}'
  )"

  # Color total lag
  local total_color="$GREEN"
  if (( total_lag == 0 )); then total_color="$GREEN"
  elif (( total_lag < 20000 )); then total_color="$YELLOW"
  else total_color="$RED"
  fi

  echo -e "${BOLD}Members:${RESET} ${MAGENTA}${BOLD}${members}${RESET}   ${BOLD}Partitions:${RESET} ${BOLD}${partitions}${RESET}   ${BOLD}Total Lag:${RESET} ${total_color}${BOLD}${total_lag}${RESET}"
  hr

  echo -e "${DIM}Sample rows (first 3 partitions):${RESET}"
  printf "${BOLD}%-24s %-6s %-12s %-12s %-8s${RESET}\n" "TOPIC" "PART" "CURRENT" "LOG_END" "LAG"

  echo "$rows" | head -n 3 | while read -r topic part cur end lag; do
    local lag_color="$DIM"
    if (( lag == 0 )); then lag_color="$GREEN"
    elif (( lag < 5000 )); then lag_color="$YELLOW"
    else lag_color="$RED"
    fi
    printf "%-24s %-6s %-12s %-12s ${lag_color}${BOLD}%-8s${RESET}\n" \
      "$topic" "$part" "$cur" "$end" "$lag"
  done

  hr
  echo -e "${DIM}If Members > 1 unexpectedly, you started the consumer twice.${RESET}"
  echo -e "${DIM}Fix:${RESET} ./stop-demo.sh then ./run-demo.sh"
}

hide_cursor
while true; do
  render
  sleep "$REFRESH_SEC"
done
