#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$HERE/99-ui.sh"

TOPIC="${TOPIC:-ops-demo-reassign-v1}"
GROUP="${GROUP:-ops-demo-monitor-group}"
BROKER="${BROKER:-broker1:9092}"

LOG_FILE="/tmp/demo4_consumer.log"
PID_FILE="/tmp/demo4_consumer.pid"

ui_tag "CONSUMER"
echo "Starting background consumer (stable + commits offsets) group=$GROUP"

# Stop old consumer if any
docker exec broker1 bash -lc "
  if [ -f '$PID_FILE' ]; then
    pid=\$(cat '$PID_FILE' 2>/dev/null || true)
    if [ -n \"\$pid\" ] && kill -0 \"\$pid\" 2>/dev/null; then
      kill \"\$pid\" 2>/dev/null || true
    fi
    rm -f '$PID_FILE'
  fi
  : > '$LOG_FILE'
" >/dev/null 2>&1 || true

# Start a long-lived consumer that auto-commits every 1s.
# NOTE: we keep output quiet; errors go to the log.
docker exec broker1 bash -lc "
  nohup kafka-console-consumer \
    --bootstrap-server '$BROKER' \
    --topic '$TOPIC' \
    --group '$GROUP' \
    --consumer-property enable.auto.commit=true \
    --consumer-property auto.commit.interval.ms=1000 \
    --consumer-property auto.offset.reset=earliest \
    --timeout-ms 600000 \
    >/dev/null 2>>'$LOG_FILE' &
  echo \$! > '$PID_FILE'
" >/dev/null

# Verify process is alive
pid="$(docker exec broker1 bash -lc "cat '$PID_FILE' 2>/dev/null || true" || true)"
if [ -z "${pid:-}" ]; then
  ui_err "Consumer failed to start (no pid). Check: docker exec broker1 bash -lc \"tail -n 50 $LOG_FILE\""
  exit 1
fi

if ! docker exec broker1 bash -lc "kill -0 '$pid' 2>/dev/null"; then
  ui_err "Consumer exited immediately. Check: docker exec broker1 bash -lc \"tail -n 50 $LOG_FILE\""
  exit 1
fi

ui_ok "Consumer running (pid=$pid)"
