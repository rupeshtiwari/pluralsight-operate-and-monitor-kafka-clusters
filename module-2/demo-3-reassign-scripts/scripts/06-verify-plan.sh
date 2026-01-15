#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/00-env.sh"

h1 "STEP 5 (T2): Verify Reassignment Progress"
hr

out="$(docker exec "$BROKER_CONTAINER" bash -lc "
  $KAFKA_ENV_FIX
  kafka-reassign-partitions --bootstrap-server $BOOTSTRAP \
    --verify --reassignment-json-file /tmp/reassign.json
")"

printf "%s\n" "$out" | while IFS= read -r line; do
  if echo "$line" | grep -qi "Status of partition reassignment"; then
    printf "%b\n" "${BOLD}${CYAN}${line}${RESET}"
  elif echo "$line" | grep -qi "completed"; then
    printf "%b\n" "${GREEN}${BOLD}${line}${RESET}"
  elif echo "$line" | grep -qi "failed\\|error"; then
    printf "%b\n" "${RED}${BOLD}${line}${RESET}"
  elif echo "$line" | grep -qi "no active reassignment"; then
    printf "%b\n" "${YELLOW}${BOLD}${line}${RESET}"
  else
    printf "%s\n" "$line"
  fi
done

hr
warn "If you see yellow lines saying replica set differs, you skipped STEP 4. Run ./scripts/05-execute-plan.sh, then verify again."
