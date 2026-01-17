#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/99-ui.sh"
source "$DIR/00-env.sh"

title "Start Producer Load"

kv "Topic" "$TOPIC"
kv "Target rate" "${RECORDS_PER_SEC} records/sec"
kv "Total" "${TOTAL_RECORDS} records"
kv "Record size" "${RECORD_SIZE_BYTES} bytes"

info "Running kafka-producer-perf-test (client-side throughput + latency)"

# Run in foreground by default for recording clarity
# The output already includes useful p50/p95/p99-style latency summary in cp-kafka image.
docker exec "$BROKER_CONTAINER" bash -lc "$KAFKA_ENV_FIX kafka-producer-perf-test \
  --topic '$TOPIC' \
  --num-records '$TOTAL_RECORDS' \
  --record-size '$RECORD_SIZE_BYTES' \
  --throughput '$RECORDS_PER_SEC' \
  --producer-props bootstrap.servers='$BOOTSTRAP' acks=all linger.ms=5 batch.size=65536 compression.type=snappy" |
  sed 's/^/  /'
