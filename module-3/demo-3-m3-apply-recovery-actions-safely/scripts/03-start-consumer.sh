#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$DIR/00-env.sh"

BOLD=$'\033[1m'; RESET=$'\033[0m'; DIM=$'\033[2m'
GREEN=$'\033[32m'; YELLOW=$'\033[33m'; CYAN=$'\033[36m'

hr() { printf '%s\n' "--------------------------------------------------------------------------------"; }

printf '%b\n' "${CYAN}${BOLD}Start Slow Consumer (detached)${RESET}"
hr

# Consumer runs inside the Kafka network so container DNS (broker1/broker2/...) works.
docker exec -d "$BROKER_CONTAINER" bash -lc "
  nohup kafka-console-consumer \
    --bootstrap-server '$BOOTSTRAP' \
    --topic '$TOPIC' \
    --group '$GROUP' \
    --consumer-property enable.auto.commit=true \
    --consumer-property auto.commit.interval.ms=1000 \
    --property print.key=false \
    --property print.value=false \
    2>/dev/null \
  | awk -v d='$SLOW_CONSUMER_DELAY_SEC' '{ system(\"sleep \" d); }' \
  > '$CONSUMER_LOG' 2>&1 &
  echo \$! > '$CONSUMER_PID'
"

printf '%b\n' "${GREEN}✅ Consumer started${RESET}  ${DIM}(PID saved in ${CONSUMER_PID})${RESET}"
printf '%b\n' "${DIM}Log:${RESET} ${BOLD}${CONSUMER_LOG}${RESET}"

# Prime the group so it shows up in kafka-consumer-groups quickly.
# Without at least one committed offset, Kafka may say the group "does not exist".
printf '\n'
printf '%b\n' "${CYAN}${BOLD}Priming group metadata...${RESET}"

for _ in $(seq 1 15); do
  out="$(
    docker exec "$BROKER_CONTAINER" bash -lc "
      env -u JMX_PORT -u KAFKA_JMX_PORT -u KAFKA_JMX_OPTS -u KAFKA_OPTS -u JAVA_TOOL_OPTIONS \
        kafka-consumer-groups --bootstrap-server '$BOOTSTRAP' --group '$GROUP' --describe 2>&1 || true
    "
  )"

  if echo "$out" | awk -v g="$GROUP" -v t="$TOPIC" '$1==g && $2==t && $3 ~ /^[0-9]+$/ { found=1 } END { exit !found }'; then
    printf '%b\n' "${GREEN}[OK]${RESET} Group is visible to kafka-consumer-groups"
    printf '%b\n' "${DIM}Next:${RESET} run ${BOLD}./scripts/10-watch-lag.sh${RESET}"
    exit 0
  fi
  sleep 1
done

printf '%b\n' "${YELLOW}Still waiting for offsets to commit.${RESET}"
printf '%b\n' "${DIM}If needed, start the producer load first, then re-run watch-lag.${RESET}"
printf '%b\n' "${DIM}Tip:${RESET} docker exec $BROKER_CONTAINER tail -n 5 '$CONSUMER_LOG'"
