#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -f "$DIR/00-env.sh" ]] && source "$DIR/00-env.sh"

TOPIC="${TOPIC:-m3-correlation-topic}"
GROUP_ID="${GROUP_ID:-${GROUP:-m3-correlation-cg}}"
BROKER_CONTAINER="${BROKER_CONTAINER:-broker1}"
BOOTSTRAP="${BOOTSTRAP:-${BOOTSTRAP_SERVERS:-broker1:9092}}"
LOG="${CONSUMER_LOG:-/tmp/ops-demo-consumer.log}"

# Colors
BOLD="\033[1m"; RESET="\033[0m"; DIM="\033[2m"
GREEN="\033[32m"; YELLOW="\033[33m"; RED="\033[31m"; CYAN="\033[36m"

echo
echo -e "${CYAN}${BOLD}Lag Snapshot${RESET} ${DIM}(group=${GROUP_ID}, topic=${TOPIC}, bootstrap=${BOOTSTRAP})${RESET}"
echo "--------------------------------------------------------------------------------"

fetch() {
  docker exec "$BROKER_CONTAINER" bash -lc "
    env -u JMX_PORT -u KAFKA_JMX_PORT -u KAFKA_JMX_OPTS -u KAFKA_OPTS -u JAVA_TOOL_OPTIONS \
      kafka-consumer-groups --bootstrap-server '$BOOTSTRAP' --describe --group '$GROUP_ID' 2>&1 || true
  "
}

print_table() {
  local raw="$1"
  printf "${BOLD}%-18s %-22s %-10s %-12s %-12s %-10s${RESET}\n" \
    "GROUP" "TOPIC" "PARTITION" "CURRENT" "LOG_END" "LAG"

  # Print only our topic rows + compute max lag
  local rows
  rows="$(echo "$raw" | awk -v g="$GROUP_ID" -v t="$TOPIC" '
    $1==g && $2==t && $6 ~ /^[0-9-]+$/ { print $1, $2, $3, $4, $5, $6 }
  ')"

  if [[ -z "${rows// /}" ]]; then
    echo -e "${YELLOW}${BOLD}⚠️  No rows for this group/topic yet.${RESET}"
    echo -e "${DIM}Tip:${RESET} start consumer, then start load."
    return 0
  fi

  local max_lag=0
  echo "$rows" | while read -r g t p cur end lag; do
    local lag_color="$DIM"
    if [[ "$lag" =~ ^[0-9]+$ ]]; then
      if (( lag == 0 )); then lag_color="$GREEN"
      elif (( lag < 5000 )); then lag_color="$YELLOW"
      else lag_color="$RED"
      fi
    fi
    printf "%-18s %-22s %-10s %-12s %-12s ${lag_color}%-10s${RESET}\n" \
      "$g" "$t" "$p" "$cur" "$end" "$lag"
  done

  # Print MAX_LAG line (useful for recovery scripts)
  max_lag="$(echo "$rows" | awk '{ if ($6 ~ /^[0-9]+$/ && $6>m) m=$6 } END { print (m==""?0:m) }')"
  echo "--------------------------------------------------------------------------------"
  echo -e "${BOLD}MAX_LAG:${RESET} ${max_lag}"
}

# Retry up to ~15 seconds so it doesn't “fail” due to timing
for _ in {1..15}; do
  out="$(fetch)"

  if echo "$out" | grep -qiE "does not exist|not found"; then
    sleep 1
    continue
  fi

  print_table "$out"
  exit 0
done

echo -e "${YELLOW}${BOLD}Consumer group not found yet.${RESET}"
echo -e "${DIM}Check consumer log:${RESET} docker exec $BROKER_CONTAINER tail -n 80 $LOG"
echo "--------------------------------------------------------------------------------"
exit 0
