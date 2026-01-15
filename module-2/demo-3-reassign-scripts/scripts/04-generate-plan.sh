#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/00-env.sh"

h1 "STEP 3 (Terminal B): Generate Reassignment Plan"
hr
printf "%b\n" "${DIM}Terminal B generates and applies the reassignment plan${RESET}"
hr
printf "%b\n" "${DIM}Goal: move replicas so broker3 participates${RESET}"
hr

docker exec "$BROKER_CONTAINER" bash -lc "
  cat > /tmp/topics-to-move.json <<EOF
{\"version\":1,\"topics\":[{\"topic\":\"$TOPIC\"}]}
EOF

  $KAFKA_ENV_FIX
  kafka-reassign-partitions --bootstrap-server $BOOTSTRAP \
    --generate \
    --topics-to-move-json-file /tmp/topics-to-move.json \
    --broker-list \"1,2,3\" | tee /tmp/reassign-generate.out

  # Extract EXACTLY ONE JSON line for CURRENT and PROPOSED.
  awk '
    /Current partition replica assignment/ {
      getline; while (\$0 ~ /^[[:space:]]*$/) getline;
      print; exit
    }
  ' /tmp/reassign-generate.out > /tmp/reassign-current.json

  awk '
    /Proposed partition reassignment configuration/ {
      getline; while (\$0 ~ /^[[:space:]]*$/) getline;
      print; exit
    }
  ' /tmp/reassign-generate.out > /tmp/reassign.json
" >/dev/null

ok "Saved plan files in broker1:"
printf "%b\n" "  ${CYAN}/tmp/reassign-current.json${RESET}  (current)"
printf "%b\n" "  ${CYAN}/tmp/reassign.json${RESET}          (proposed)"
hr

cur_json="$(docker exec "$BROKER_CONTAINER" bash -lc "cat /tmp/reassign-current.json")"
prop_json="$(docker exec "$BROKER_CONTAINER" bash -lc "cat /tmp/reassign.json")"

echo "$cur_json" | jq . >/dev/null || fail "Current JSON is invalid"
echo "$prop_json" | jq . >/dev/null || fail "Proposed JSON is invalid"

printf "%b\n" "${BOLD}${CYAN}Replica Move Summary:${RESET}"
hr
printf "%b\n" "${BOLD}${BLUE}Partition${RESET}  ${BOLD}${BLUE}Current${RESET}  ${BOLD}${BLUE}Proposed${RESET}"

cur_tsv="$(echo "$cur_json" | jq -r '.partitions[] | "\(.partition)\t\(.replicas|join(","))"')"
prop_tsv="$(echo "$prop_json" | jq -r '.partitions[] | "\(.partition)\t\(.replicas|join(","))"')"

awk -F'\t' '
  NR==FNR { cur[$1]=$2; next }
  { prop[$1]=$2 }
  END {
    for (i=0; i<1000; i++) if (i in cur || i in prop) {
      c = (i in cur) ? cur[i] : "-"
      p = (i in prop) ? prop[i] : "-"
      printf "%d\t%s\t%s\n", i, c, p
    }
  }
' <(printf "%s\n" "$cur_tsv") <(printf "%s\n" "$prop_tsv") | column -t -s $'\t'

hr
printf "%b\n" "${BOLD}${CYAN}Execution Plan Preview:${RESET}"
hr
printf "%s\n" "$prop_json" | jq -c -C '.partitions[] | {partition, replicas}'

hr
warn "Next: run ./scripts/05-execute-plan.sh"
