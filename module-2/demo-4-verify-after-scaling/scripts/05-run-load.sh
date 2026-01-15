#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/00-env.sh"
source "$(dirname "$0")/99-ui.sh"

# Producer load to validate post-scaling stability.
# Keep this short for a 4-minute demo.

ui_h1 "PRODUCER LOAD (controlled post-scale test)"
ui_kv "Topic" "$TOPIC"
ui_kv "Target throughput" "20000 records/sec"
ui_kv "Records" "500000"
echo

docker exec -it "$BROKER_CONTAINER" bash -lc "
  $KAFKA_ENV_FIX
  kafka-producer-perf-test \
    --topic $TOPIC \
    --num-records 500000 \
    --record-size 512 \
    --throughput 20000 \
    --producer-props bootstrap.servers=$BOOTSTRAP acks=1 linger.ms=5 batch.size=65536
"
