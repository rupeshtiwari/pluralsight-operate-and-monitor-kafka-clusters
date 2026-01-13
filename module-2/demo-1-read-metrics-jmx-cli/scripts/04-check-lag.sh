#!/usr/bin/env bash
set -euo pipefail

GROUP="ops-demo-cg"
TOPIC="ops-demo-metrics"

# Colors
BOLD="\033[1m"
RESET="\033[0m"
DIM="\033[2m"
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
CYAN="\033[36m"

# Print a clean table from kafka-consumer-groups output
print_table() {
  local raw="$1"

  # Header
  printf "${BOLD}%-14s %-16s %-10s %-14s %-14s %-10s${RESET}\n" \
    "GROUP" "TOPIC" "PARTITION" "CURRENT" "LOG_END" "LAG"

  echo "$raw" | awk -v group="$GROUP" -v topic="$TOPIC" '
    BEGIN { OFS=" " }
    $1==group && $2==topic {
      # fields: GROUP TOPIC PARTITION CURRENT-OFFSET LOG-END-OFFSET LAG ...
      print $1, $2, $3, $4, $5, $6
    }
  ' | while read -r g t p cur end lag; do
    # colorize lag
    if [[ "$lag" == "-" || -z "$lag" ]]; then
      lag_color="$DIM"
    elif (( lag == 0 )); then
      lag_color="$GREEN"
    elif (( lag < 5000 )); then
      lag_color="$YELLOW"
    else
      lag_color="$RED"
    fi

    printf "%-14s %-16s %-10s %-14s %-14s ${lag_color}%-10s${RESET}\n" \
      "$g" "$t" "$p" "$cur" "$end" "$lag"
  done
}

run_once() {
  # IMPORTANT: disable CLI JMX env to avoid port 9999 conflicts
  docker exec broker1 bash -lc "
    unset JMX_PORT KAFKA_JMX_PORT KAFKA_JMX_OPTS;
    kafka-consumer-groups --bootstrap-server broker1:9092 --describe --group $GROUP
  " 2>/dev/null
}

echo -e "${CYAN}${BOLD}Lag Snapshot${RESET} ${DIM}(group=${GROUP}, topic=${TOPIC})${RESET}"
echo ""

out="$(run_once || true)"

# Handle "group does not exist" cleanly
if echo "$out" | grep -qi "does not exist"; then
  echo -e "${YELLOW}${BOLD}Consumer group not found yet${RESET} ${DIM}(expected before consumer starts)${RESET}"
  exit 0
fi

print_table "$out"