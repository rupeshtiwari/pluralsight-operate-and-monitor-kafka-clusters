#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/99-ui.sh"
source "$DIR/00-env.sh"

LOG="/tmp/m3_demo1_consumer.log"

title "Start Background Consumer"

info "Launching kafka-console-consumer (group=$GROUP)"
info "Log file: $LOG"

# Start inside broker1 so host networking is consistent.
# --from-beginning ensures offsets advance even if topic already has data.
# Redirect to a log to keep recording clean.
docker exec -d "$BROKER_CONTAINER" bash -lc "$KAFKA_ENV_FIX nohup kafka-console-consumer --bootstrap-server '$BOOTSTRAP' --topic '$TOPIC' --group '$GROUP' --from-beginning --property print.timestamp=true >'$LOG' 2>&1 &"

# Quick visibility
sleep 1
if docker exec "$BROKER_CONTAINER" bash -lc "test -f '$LOG'" >/dev/null 2>&1; then
  ok "Consumer started"
else
  warn "Consumer log not found yet"
fi

info "Tip: tail the consumer log if group rows are missing"
kv "Tail" "docker exec broker1 bash -lc 'tail -n 20 $LOG'"
