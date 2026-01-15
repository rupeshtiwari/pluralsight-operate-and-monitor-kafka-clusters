#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/00-env.sh"

# Producer load to validate post-scaling stability.
# Keep this short for a 4-minute demo.

docker exec -it "$BROKER_CONTAINER" bash -lc "
  $KAFKA_ENV_FIX
  kafka-producer-perf-test \
    --topic $TOPIC \
    --num-records 500000 \
    --record-size 512 \
    --throughput 20000 \
    --producer-props bootstrap.servers=$BOOTSTRAP acks=1 linger.ms=5 batch.size=65536
"
