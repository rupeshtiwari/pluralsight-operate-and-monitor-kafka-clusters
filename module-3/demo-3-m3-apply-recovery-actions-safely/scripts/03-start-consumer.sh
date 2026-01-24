#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/00-env.sh"

BROKER_CONTAINER="${BROKER_CONTAINER:-broker1}"
BOOTSTRAP="${BOOTSTRAP_SERVERS:-broker1:9092}"

SLEEP_SEC="${SLOW_CONSUMER_DELAY_SEC:-0.05}"
AUTO_COMMIT_MS="${AUTO_COMMIT_MS:-1000}"

LOG_FILE="${CONSUMER_LOG:-/tmp/ops-demo-consumer.log}"
PID_FILE="/tmp/ops-demo-consumer.pid"

RED=$'\033[31m'; GREEN=$'\033[32m'; CYAN=$'\033[36m'; BOLD=$'\033[1m'; RESET=$'\033[0m'
hr(){ printf '%s\n' "--------------------------------------------------------------------------------"; }
die(){ echo -e "${RED}[ERR]${RESET} $*" >&2; exit 1; }

echo -e "${CYAN}${BOLD}🐢 Start Slow Consumer (detached)${RESET}"
hr
printf "📌 Topic:      %s\n" "$TOPIC"
printf "👥 Group:      %s\n" "$GROUP_ID"
printf "🛰️ Bootstrap:  %s\n" "$BOOTSTRAP"
printf "🐌 Sleep:      %ss/msg\n" "$SLEEP_SEC"
printf "🪵 Log:        %s (inside %s)\n" "$LOG_FILE" "$BROKER_CONTAINER"
hr

docker inspect "$BROKER_CONTAINER" >/dev/null 2>&1 || die "Container '$BROKER_CONTAINER' not found."
docker exec "$BROKER_CONTAINER" bash -lc "kafka-broker-api-versions --bootstrap-server '$BOOTSTRAP' >/dev/null 2>&1" \
  || die "Kafka not reachable on $BOOTSTRAP"

existing_pid="$(docker exec "$BROKER_CONTAINER" bash -lc "cat '$PID_FILE' 2>/dev/null || true" | tr -d '[:space:]')"
if [[ -n "${existing_pid:-}" ]] && docker exec "$BROKER_CONTAINER" bash -lc "kill -0 '$existing_pid' >/dev/null 2>&1"; then
  echo -e "${GREEN}✅ Consumer already running (pid=$existing_pid)${RESET}"
  echo "Tail: docker exec $BROKER_CONTAINER tail -n 30 $LOG_FILE"
  exit 0
fi

docker exec "$BROKER_CONTAINER" bash -lc "rm -f '$PID_FILE'; : > '$LOG_FILE'" >/dev/null 2>&1 || true

docker exec "$BROKER_CONTAINER" bash -lc "
  set -euo pipefail
  nohup bash -lc '
    set -euo pipefail
    kafka-console-consumer \
      --bootstrap-server \"$BOOTSTRAP\" \
      --topic \"$TOPIC\" \
      --group \"$GROUP_ID\" \
      --consumer-property enable.auto.commit=true \
      --consumer-property auto.commit.interval.ms=$AUTO_COMMIT_MS \
      --consumer-property max.poll.records=1 \
      --consumer-property auto.offset.reset=latest \
    | while IFS= read -r line; do
        echo \"\$line\"
        sleep \"$SLEEP_SEC\"
      done
  ' >> '$LOG_FILE' 2>&1 &
  echo \$! > '$PID_FILE'
"

new_pid="$(docker exec "$BROKER_CONTAINER" bash -lc "cat '$PID_FILE' 2>/dev/null || true" | tr -d '[:space:]')"
if [[ -z "${new_pid:-}" ]] || ! docker exec "$BROKER_CONTAINER" bash -lc "kill -0 '$new_pid' >/dev/null 2>&1"; then
  echo -e "${RED}❌ Consumer failed to start.${RESET}"
  docker exec "$BROKER_CONTAINER" bash -lc "tail -n 120 '$LOG_FILE' || true"
  exit 1
fi

echo -e "${GREEN}✅ Consumer started (pid=$new_pid)${RESET}"
echo "Tail: docker exec $BROKER_CONTAINER tail -n 30 $LOG_FILE"
