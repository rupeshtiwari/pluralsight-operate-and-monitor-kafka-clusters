#!/usr/bin/env bash
set -euo pipefail

TOPIC="${TOPIC:-ops-demo-observability}"
GROUP="${GROUP:-ops-demo-cg}"
LOG="/tmp/ops-demo-consumer.log"

# Colors
BOLD="\033[1m"
RESET="\033[0m"
DIM="\033[2m"
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
CYAN="\033[36m"

echo
echo -e "${CYAN}${BOLD}Lag Snapshot${RESET} ${DIM}(group=${GROUP}, topic=${TOPIC})${RESET}"
echo "--------------------------------------------------------------------------"

fetch() {
  docker exec broker1 bash -lc "
    env -u JMX_PORT -u KAFKA_JMX_PORT -u KAFKA_JMX_OPTS -u KAFKA_OPTS -u JAVA_TOOL_OPTIONS \
      kafka-consumer-groups --bootstrap-server broker1:9092 --describe --group '$GROUP' 2>&1 || true
  "
}

print_table() {
  local raw="$1"
  printf "${BOLD}%-14s %-24s %-10s %-14s %-14s %-10s${RESET}\n" \
    "GROUP" "TOPIC" "PARTITION" "CURRENT" "LOG_END" "LAG"

  echo "$raw" | awk -v group="$GROUP" -v topic="$TOPIC" '
    $1==group && $2==topic { print $1, $2, $3, $4, $5, $6 }
  ' | while read -r g t p cur end lag; do
    if [[ "$lag" == "-" || -z "${lag:-}" ]]; then
      lag_color="$DIM"
    elif [[ "$lag" =~ ^[0-9]+$ ]] && (( lag == 0 )); then
      lag_color="$GREEN"
    elif [[ "$lag" =~ ^[0-9]+$ ]] && (( lag < 5000 )); then
      lag_color="$YELLOW"
    else
      lag_color="$RED"
    fi

    printf "%-14s %-24s %-10s %-14s %-14s ${lag_color}%-10s${RESET}\n" \
      "$g" "$t" "$p" "$cur" "$end" "$lag"
  done
}

# Retry up to ~15 seconds so demo never "fails" due to timing
for _ in {1..15}; do
  out="$(fetch)"
  if echo "$out" | grep -qi "does not exist"; then
    sleep 1
    continue
  fi
  print_table "$out"
  echo "--------------------------------------------------------------------------"
  exit 0
done

echo -e "${YELLOW}${BOLD}Consumer group not found yet.${RESET}"
echo -e "${DIM}Consumer may have failed. Check:${RESET} docker exec broker1 tail -n 80 $LOG"
echo "--------------------------------------------------------------------------"
exit 0
