#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/00-env.sh"

PID_FILE="/tmp/demo4_consumer.pid"
LOG_FILE="/tmp/demo4_consumer.log"

# Stop any previous consumer started by this script
if docker exec "$BROKER_CONTAINER" bash -lc "test -s $PID_FILE" >/dev/null 2>&1; then
  old_pid=$(docker exec "$BROKER_CONTAINER" bash -lc "cat $PID_FILE" || true)
  if [[ -n "${old_pid:-}" ]]; then
    docker exec "$BROKER_CONTAINER" bash -lc "kill $old_pid >/dev/null 2>&1 || true"
  fi
  docker exec "$BROKER_CONTAINER" bash -lc "rm -f $PID_FILE" || true
fi

# Start a long-running consumer group in the background.
# This makes lag metrics meaningful when you later start producer load.
echo "Starting background consumer group '$GROUP' on topic '$TOPIC' (logs: $LOG_FILE)"

# NOTE: We must escape $! so it is expanded inside the container shell, not by this script.
docker exec "$BROKER_CONTAINER" bash -lc "
  set -e
  $KAFKA_ENV_FIX
  nohup kafka-console-consumer \\
    --bootstrap-server $BOOTSTRAP \\
    --topic $TOPIC \\
    --group $GROUP \\
    --from-beginning \\
    --formatter kafka.tools.DefaultMessageFormatter \\
    --property print.partition=true \\
    --property print.offset=true \\
    --property print.value=false \\
    --property print.key=false \\
    --property print.timestamp=false \\
    > $LOG_FILE 2>&1 &
  echo \$! > $PID_FILE
"

pid=$(docker exec "$BROKER_CONTAINER" bash -lc "cat $PID_FILE" || true)
if [[ -z "${pid:-}" ]]; then
  echo "ERROR: consumer failed to start"
  exit 1
fi

echo "Consumer started (pid=$pid)"
