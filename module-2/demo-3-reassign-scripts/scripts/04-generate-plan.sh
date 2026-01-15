#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/00-env.sh"

h1 "STEP 3 (Terminal B): Generate Reassignment Plan"
hr
printf "%b\n" "${DIM}Goal: add broker3 into replica sets so the cluster is not concentrated on brokers 1 and 2${RESET}"
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

  # CURRENT assignment JSON
  awk '
    /Current partition replica assignment/ {flag=1; next}
    flag {print}
  ' /tmp/reassign-generate.out | sed '/^[[:space:]]*$/d' > /tmp/reassign-current.json

  # PROPOSED assignment JSON
  awk '
    /Proposed partition reassignment configuration/ {flag=1; next}
    /Current partition replica assignment/ {flag=0}
    flag {print}
  ' /tmp/reassign-generate.out | sed '/^[[:space:]]*$/d' > /tmp/reassign.json
" >/dev/null

ok "Saved JSON in broker1:"
printf "%b\n" "  ${CYAN}/tmp/reassign-current.json${RESET}  (before)"
printf "%b\n" "  ${CYAN}/tmp/reassign.json${RESET}          (proposed)"
hr

cur_json="$(docker exec "$BROKER_CONTAINER" bash -lc "cat /tmp/reassign-current.json")"
prop_json="$(docker exec "$BROKER_CONTAINER" bash -lc "cat /tmp/reassign.json")"

printf "%b\n" "${BOLD}${CYAN}Replica movement summary (what you narrate):${RESET}"
hr
printf "%b\n" "${BOLD}${BLUE}Partition${RESET}  ${BOLD}${BLUE}Current Replicas${RESET}  ${BOLD}${BLUE}Proposed Replicas${RESET}"

export CUR="$cur_json"
export PROP="$prop_json"
python3 - <<'PY' | column -t -s $'\t'
import os, json
cur = json.loads(os.environ["CUR"])
prop = json.loads(os.environ["PROP"])

def to_map(doc):
    out = {}
    for p in doc.get("partitions", []):
        out[p["partition"]] = ",".join(str(x) for x in p["replicas"])
    return out

mcur = to_map(cur)
mprop = to_map(prop)
for part in sorted(set(mcur) | set(mprop)):
    print(f"{part}\t{mcur.get(part,'-')}\t{mprop.get(part,'-')}")
PY

hr
printf "%b\n" "${BOLD}${CYAN}Proposed JSON (pretty, 3 columns):${RESET}"
hr
printf "%s\n" "$prop_json" | jq . | pr -3 -t -w 180
hr

warn "Next (mandatory): run ./scripts/05-execute-plan.sh"
