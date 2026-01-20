#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/00-env.sh"

# Opinionated defaults so you can run: ./scripts/02-start-load.sh
# (You *can* override, but you don't have to.)
DURATION_SEC="${DURATION_SEC:-240}"
TARGET_RPS="${TARGET_RPS:-25000}"
WINDOW_SEC="${WINDOW_SEC:-5}"
RECORD_SIZE="${RECORD_SIZE:-200}"

# How many records per perf-test run (gives you one clean status line every WINDOW_SEC)
CHUNK_RECORDS=$(( TARGET_RPS * WINDOW_SEC ))

printf "Starting producer load (topic=%s, duration=%ss, target≈%s rps)\n" "$TOPIC" "$DURATION_SEC" "$TARGET_RPS"
printf "Expected in Grafana: Throughput rises, p99 stays low until the incident.\n"

end=$(( $(date +%s) + DURATION_SEC ))

# Keep running even if one batch fails during leader churn
set +e

while (( $(date +%s) < end )); do
  out=$(docker exec broker1 bash -lc "
    env -u JMX_PORT -u KAFKA_JMX_PORT -u KAFKA_JMX_OPTS -u KAFKA_OPTS -u JAVA_TOOL_OPTIONS \
      kafka-producer-perf-test \
        --topic '$TOPIC' \
        --num-records $CHUNK_RECORDS \
        --record-size $RECORD_SIZE \
        --throughput $TARGET_RPS \
        --producer-props bootstrap.servers='$BOOTSTRAP' acks=1 linger.ms=5 batch.size=65536 2>&1
  ")
  ec=$?

  # Print only the most useful line for the video
  last_line=$(printf "%s\n" "$out" | tail -n 1)
  if [[ -n "$last_line" ]]; then
    echo "$last_line"
  else
    echo "(producer-perf-test ran, but produced no summary line)"
  fi

  if [[ $ec -ne 0 ]]; then
    # During broker restart you may see NOT_LEADER_OR_FOLLOWER or timeouts.
    # That's actually *good* teaching signal. Keep going.
    echo "WARN: producer batch exited $ec (continuing...)" 1>&2
  fi

done

echo "✅ Load finished (~${DURATION_SEC}s)."
