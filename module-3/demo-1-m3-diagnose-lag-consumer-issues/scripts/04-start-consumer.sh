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
GROUP_ID="${GROUP_ID:-m3-demo1-diagnose-group}"

LOG_FILE="${LOG_FILE:-/tmp/m3_demo1_consumer.log}"

hr() { printf '%s\n' "────────────────────────────────────────────────────────────────────────────────"; }

if [[ "${1:-}" == "--prime" ]]; then
  echo "Prime Consumer Group (create group, then exit)"
  hr
  docker exec "$BROKER_CONTAINER" bash -lc "
    kafka-console-consumer \
      --bootstrap-server '$BOOTSTRAP_SERVER' \
      --topic '$TOPIC_NAME' \
      --group '$GROUP_ID' \
      --consumer-property enable.auto.commit=true \
      --consumer-property auto.commit.interval.ms=1000 \
      --timeout-ms 3000 \
      --max-messages 1 >/dev/null 2>&1 || true
  "
  echo "[OK] Group primed: $GROUP_ID"
  exit 0
fi

echo "Start Background Consumer"
hr
echo "Launching kafka-console-consumer (group=$GROUP_ID)"
echo "Log file: $LOG_FILE"

docker exec -d "$BROKER_CONTAINER" bash -lc "
  nohup kafka-console-consumer \
    --bootstrap-server '$BOOTSTRAP_SERVER' \
    --topic '$TOPIC_NAME' \
    --group '$GROUP_ID' \
    --consumer-property enable.auto.commit=true \
    --consumer-property auto.commit.interval.ms=1000 \
    --property print.key=false \
    --property print.value=false \
    > '$LOG_FILE' 2>&1 &
  disown
"

echo "[OK] Consumer started"
echo "Tip: tail the consumer log if needed"
echo "Tail: docker exec $BROKER_CONTAINER bash -lc 'tail -n 20 $LOG_FILE'"
