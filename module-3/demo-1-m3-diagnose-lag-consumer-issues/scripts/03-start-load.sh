#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/00-env.sh" ]]; then
  # shellcheck disable=SC1091
  source "$SCRIPT_DIR/00-env.sh"
fi

BROKER_CONTAINER="${BROKER_CONTAINER:-broker1}"
BOOTSTRAP_SERVER="${BOOTSTRAP_SERVER:-broker1:9092}"
TOPIC_NAME="${TOPIC_NAME:-m3-demo1-lag-topic}"

# Demo tuning: 30 batches -> ~30 visible lines
BATCH_RECORDS="${BATCH_RECORDS:-100000}"   # per batch
BATCHES="${BATCHES:-30}"                  # 20–40 lines: set 20..40
THROUGHPUT="${THROUGHPUT:-50000}"         # records/sec
RECORD_SIZE="${RECORD_SIZE:-512}"         # bytes

hr() { printf '%s\n' "────────────────────────────────────────────────────────────────────────────────"; }

echo "Start Producer Load (batched)"
hr
echo "Topic:        $TOPIC_NAME"
echo "Throughput:   ${THROUGHPUT} records/sec"
echo "Batch size:   ${BATCH_RECORDS} records"
echo "Batches:      ${BATCHES} (expect ~${BATCHES} lines)"
echo "Record size:  ${RECORD_SIZE} bytes"
echo

for i in $(seq 1 "$BATCHES"); do
  echo "Batch $i/$BATCHES"
  docker exec "$BROKER_CONTAINER" bash -lc "
    unset JMX_PORT KAFKA_JMX_OPTS KAFKA_JMX_PORT;
    kafka-producer-perf-test \
      --topic '$TOPIC_NAME' \
      --num-records '$BATCH_RECORDS' \
      --record-size '$RECORD_SIZE' \
      --throughput '$THROUGHPUT' \
      --producer-props bootstrap.servers='$BOOTSTRAP_SERVER' acks=1 linger.ms=5 batch.size=65536
  " | tail -n 1
  sleep 1
done
