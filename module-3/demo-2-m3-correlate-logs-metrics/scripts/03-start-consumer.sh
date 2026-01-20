#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/00-env.sh"

# Make lag visible on purpose: consume slowly.
# If the producer sends 20k+/sec, a ~100 msg/sec consumer guarantees lag.
PROCESS_DELAY_SEC="${PROCESS_DELAY_SEC:-0.01}"

echo "Starting SLOW consumer inside broker1 (topic=$TOPIC, group=$GROUP, delay=${PROCESS_DELAY_SEC}s/msg)..."
echo "Consumer log: $CONSUMER_LOG"

# If an old demo consumer is running, stop it cleanly.
docker exec broker1 bash -lc "
  pkill -f 'kafka-console-consumer.*--group $GROUP' >/dev/null 2>&1 || true
  rm -f '$CONSUMER_LOG'
" >/dev/null

# Start in background INSIDE the container so it survives your terminal.
docker exec -d broker1 bash -lc "
  set -euo pipefail
  export KAFKA_OPTS=''
  (
    kafka-console-consumer \
      --bootstrap-server '$BOOTSTRAP' \
      --topic '$TOPIC' \
      --group '$GROUP' \
      --property print.timestamp=false \
      --property print.key=false \
      --property print.headers=false \
      2>>'$CONSUMER_LOG' \
    | while IFS= read -r _line; do
        # simulate slow processing
        sleep '$PROCESS_DELAY_SEC'
      done
  ) >>'$CONSUMER_LOG' 2>&1 &
  echo \$! > /tmp/ops-demo-consumer.pid
" >/dev/null

echo "✅ Consumer running."
echo "Tip: tail it with: docker exec broker1 tail -n 20 $CONSUMER_LOG"
