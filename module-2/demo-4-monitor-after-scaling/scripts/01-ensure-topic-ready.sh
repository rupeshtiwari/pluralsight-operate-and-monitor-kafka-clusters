#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/00-env.sh"

# This demo assumes Demo 3 already ran.
# To keep the demo runnable standalone, this script will:
# 1) Create the topic if it does not exist
# 2) Ensure a reassignment plan exists and is executed

exists=$(docker exec "$BROKER_CONTAINER" bash -lc "$KAFKA_ENV_FIX kafka-topics --bootstrap-server $BOOTSTRAP --list | grep -x '$TOPIC' || true")

if [[ -z "$exists" ]]; then
  echo "Topic '$TOPIC' not found. Creating an intentionally imbalanced topic first (brokers 1 and 2 only)."
  docker exec "$BROKER_CONTAINER" bash -lc "
    $KAFKA_ENV_FIX
    kafka-topics --bootstrap-server $BOOTSTRAP \
      --create --if-not-exists \
      --topic $TOPIC \
      --replica-assignment 1:2,1:2,1:2,1:2,1:2,1:2
  "
fi

# Generate reassignment json if missing
has_plan=$(docker exec "$BROKER_CONTAINER" bash -lc "test -s /tmp/reassign.json && echo yes || echo no")
if [[ "$has_plan" != "yes" ]]; then
  echo "Generating reassignment plan -> /tmp/reassign.json"
  docker exec "$BROKER_CONTAINER" bash -lc "
    cat > /tmp/topics-to-move.json <<JSON
{\"version\":1,\"topics\":[{\"topic\":\"$TOPIC\"}]}
JSON

    $KAFKA_ENV_FIX
    kafka-reassign-partitions --bootstrap-server $BOOTSTRAP \
      --generate \
      --topics-to-move-json-file /tmp/topics-to-move.json \
      --broker-list \"1,2,3\" | tee /tmp/reassign-generate.out

    awk '
      /Proposed partition reassignment configuration/ {flag=1; next}
      /Current partition replica assignment/ {flag=0}
      flag {print}
    ' /tmp/reassign-generate.out | sed '/^[[:space:]]*$/d' > /tmp/reassign.json

    echo "Wrote: /tmp/reassign.json"
  "
fi

# Execute the plan (idempotent)
echo "Executing reassignment plan (safe to re-run)"
docker exec "$BROKER_CONTAINER" bash -lc "
  $KAFKA_ENV_FIX
  kafka-reassign-partitions --bootstrap-server $BOOTSTRAP \
    --execute --reassignment-json-file /tmp/reassign.json
"

echo "Verify plan status"
docker exec "$BROKER_CONTAINER" bash -lc "
  $KAFKA_ENV_FIX
  kafka-reassign-partitions --bootstrap-server $BOOTSTRAP \
    --verify --reassignment-json-file /tmp/reassign.json
"

echo "Done. Topic is ready for post-scaling verification."
