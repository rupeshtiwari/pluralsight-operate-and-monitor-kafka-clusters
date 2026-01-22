#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/00-env.sh"

BOLD="\033[1m"; RESET="\033[0m"; DIM="\033[2m"
GREEN="\033[32m"; YELLOW="\033[33m"; RED="\033[31m"; CYAN="\033[36m"

hr() { printf "%s\n" "--------------------------------------------------------------------------------"; }

echo
echo -e "${CYAN}${BOLD}Start Slow Consumer (detached)${RESET}"
hr
printf "%-10s %s\n" "topic" "$TOPIC"
printf "%-10s %s\n" "group" "$GROUP"
printf "%-10s %s\n" "delay" "${SLOW_CONSUMER_DELAY_SEC}s/msg"
printf "%-10s %s\n" "log" "$CONSUMER_LOG"
printf "%-10s %s\n" "pid" "$CONSUMER_PID"
printf "%-10s %s\n" "bootstrap" "$BOOTSTRAP"
hr
echo

# Kill any previous consumer process if pid file exists
docker exec "$BROKER_CONTAINER" bash -lc "
  if [[ -f '$CONSUMER_PID' ]]; then
    oldpid=\$(cat '$CONSUMER_PID' 2>/dev/null || true)
    if [[ -n \"\$oldpid\" ]]; then
      kill \"\$oldpid\" >/dev/null 2>&1 || true
    fi
    rm -f '$CONSUMER_PID' >/dev/null 2>&1 || true
  fi
" >/dev/null

# Start a detached consumer inside broker1 and write pid + log lines with timestamps
docker exec -d "$BROKER_CONTAINER" bash -lc "
  set -euo pipefail

  : > '$CONSUMER_LOG'

  (
    env -u JMX_PORT -u KAFKA_JMX_PORT -u KAFKA_JMX_OPTS -u KAFKA_OPTS -u JAVA_TOOL_OPTIONS \
      kafka-console-consumer \
        --bootstrap-server '$BOOTSTRAP' \
        --topic '$TOPIC' \
        --group '$GROUP' \
        --consumer-property max.poll.records=1 \
        --consumer-property auto.offset.reset=earliest \
        --property print.key=false \
        --property print.timestamp=false \
        --property print.headers=false \
    | while IFS= read -r line; do
        printf '[%s] %s\n' \"\$(date +'%Y-%m-%d %H:%M:%S,%3N')\" \"\$line\" >> '$CONSUMER_LOG'
        sleep '$SLOW_CONSUMER_DELAY_SEC'
      done
  ) &

  echo \$! > '$CONSUMER_PID'
" >/dev/null

echo -e "${GREEN}${BOLD}[OK] Slow consumer started${RESET}"
echo -e "${DIM}Tip:${RESET} docker exec $BROKER_CONTAINER bash -lc \"tail -n 20 '$CONSUMER_LOG'\""
echo
