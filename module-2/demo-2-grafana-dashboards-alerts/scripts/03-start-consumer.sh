#!/usr/bin/env bash
set -euo pipefail

TOPIC="${TOPIC:-ops-demo-observability}"
GROUP="${GROUP:-ops-demo-cg}"
LOG="/tmp/ops-demo-consumer.log"

echo "Starting consumer inside broker1 (topic=$TOPIC, group=$GROUP)..."
echo "Consumer log: $LOG"

# Kill older consumers (best-effort)
docker exec broker1 bash -lc "
  pkill -f \"kafka-console-consumer.*--group ${GROUP}\" >/dev/null 2>&1 || true
" >/dev/null || true

# Start consumer detached and create log in the SAME process
docker exec -d broker1 bash -lc "
  rm -f '${LOG}'; : > '${LOG}';
  exec env -u JMX_PORT -u KAFKA_JMX_PORT -u KAFKA_JMX_OPTS -u KAFKA_OPTS -u JAVA_TOOL_OPTIONS \
    kafka-console-consumer \
      --bootstrap-server broker1:9092 \
      --topic '${TOPIC}' \
      --group '${GROUP}' \
      --from-beginning \
      --consumer-property enable.auto.commit=true \
      --consumer-property auto.commit.interval.ms=1000 \
      --consumer-property auto.offset.reset=earliest \
      >> '${LOG}' 2>&1
"

sleep 1

PID_LINE="$(docker exec broker1 bash -lc "pgrep -af kafka-console-consumer | head -n 1 || true")"
if [[ -n "$PID_LINE" ]]; then
  echo "✅ Consumer running."
  exit 0
fi

echo "❌ Consumer did not stay running. Last log lines:"
docker exec broker1 bash -lc "tail -n 80 '${LOG}' 2>/dev/null || echo 'NO LOG FILE'"
exit 1
