#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$DIR/00-env.sh"

# ✅ Goal: a clean, repeatable producer load for recording.
# - No env vars needed to run.
# - Keeps the terminal readable (only prints perf summary lines).
# - Waits for Kafka to be reachable before starting.

# Defaults (override only if you really want to)
DURATION_SEC="${DURATION_SEC:-240}"   # ~4 minutes (good for a 2–3 min recording)
TARGET_RPS="${TARGET_RPS:-25000}"     # msgs/sec target
RECORD_SIZE="${RECORD_SIZE:-200}"     # bytes per record
WINDOW_SEC="${WINDOW_SEC:-5}"         # seconds per perf batch

WARN_LOG="/tmp/ops-demo-producer.warn"

hr() { printf '%s\n' "────────────────────────────────────────────────────────────────────────────────"; }

wait_for_kafka() {
  # We run inside the broker container so we can use broker DNS.
  local tries=40
  while (( tries-- > 0 )); do
    if docker exec "$BROKER_CONTAINER" bash -lc "kafka-broker-api-versions --bootstrap-server '$BOOTSTRAP' >/dev/null 2>&1"; then
      return 0
    fi
    sleep 1
  done
  return 1
}

echo "Start producer load (clean output)"
hr
echo "Topic:     $TOPIC"
echo "Bootstrap: $BOOTSTRAP"
echo "Target:    ~${TARGET_RPS} msg/s"
echo "Duration:  ~${DURATION_SEC}s"
echo "(Warnings suppressed to: $WARN_LOG)"
echo

if ! wait_for_kafka; then
  echo "[ERR] Kafka not reachable via $BOOTSTRAP"
  echo "Tip: run ./run-demo.sh again and wait for brokers to be healthy"
  exit 1
fi

TOTAL_WINDOWS=$(( DURATION_SEC / WINDOW_SEC ))
(( TOTAL_WINDOWS < 1 )) && TOTAL_WINDOWS=1

RECORDS_PER_WINDOW=$(( TARGET_RPS * WINDOW_SEC ))

for _ in $(seq 1 "$TOTAL_WINDOWS"); do
  # Capture output, but only print the summary lines you want on camera.
  out="$(
    docker exec "$BROKER_CONTAINER" bash -lc "
      kafka-producer-perf-test \
        --topic '$TOPIC' \
        --num-records $RECORDS_PER_WINDOW \
        --record-size $RECORD_SIZE \
        --throughput $TARGET_RPS \
        --producer-props bootstrap.servers='$BOOTSTRAP' acks=1 linger.ms=10 batch.size=32768 \
        2>>'$WARN_LOG'
    " || true
  )"

  # Print only the perf-test summary line(s):
  # "100000 records sent, 20000.0 records/sec ..."
  line="$(printf '%s\n' "$out" | grep -E '^[0-9]+ records sent,' | tail -n 1 || true)"

  if [[ -n "$line" ]]; then
    echo "$line"
  else
    # If Kafka was restarting, perf-test may not emit a summary. Keep it one clean line.
    echo "(producer batch skipped: broker churn / metadata refresh)"
  fi

  sleep 1
done

echo
echo "[OK] Load finished (Ctrl+C anytime)."
