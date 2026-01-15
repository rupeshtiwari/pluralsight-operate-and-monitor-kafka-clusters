#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/00-env.sh"

# Real traffic so reassignment isn't "in a vacuum"
docker exec "$BROKER_CONTAINER" bash -lc "
  $KAFKA_ENV_FIX
  kafka-producer-perf-test \
    --topic $TOPIC \
    --num-records 3000000 \
    --record-size 512 \
    --throughput 20000 \
    --producer-props bootstrap.servers=$BOOTSTRAP acks=1 linger.ms=5 batch.size=65536
"
