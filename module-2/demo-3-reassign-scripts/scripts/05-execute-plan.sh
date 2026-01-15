#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/00-env.sh"

h1 "STEP 4 (Terminal B): Execute Reassignment"
hr
printf "%b\n" "${DIM}Applying the proposed plan stored in broker1:${RESET} ${CYAN}/tmp/reassign.json${RESET}"
hr

out="$(docker exec "$BROKER_CONTAINER" bash -lc "
  $KAFKA_ENV_FIX
  kafka-reassign-partitions --bootstrap-server $BOOTSTRAP \
    --execute --reassignment-json-file /tmp/reassign.json
")"

# Extract the one long success line and reflow it
success_line="$(printf "%s\n" "$out" | grep -E 'Successfully started partition reassignments' || true)"

if [[ -z "$success_line" ]]; then
  printf "%b\n" "${RED}${BOLD}ERROR:${RESET} Execute did not return the expected success message."
  printf "%s\n" "$out"
  exit 1
fi

# Show a clean, wrapped version (partition list one per line)
printf "%b\n" "${GREEN}${BOLD}Reassignment started for partitions:${RESET}"

# Get the CSV list after "for "
csv="$(echo "$success_line" | sed -E 's/^.*for[[:space:]]+//')"

# Print as bullets, wrapped nicely
echo "$csv" | tr ',' '\n' | sed 's/^/  • /'

hr
printf "%b\n" "${DIM}Rollback info saved (not shown):${RESET} ${CYAN}/tmp/reassign-current.json${RESET}"
