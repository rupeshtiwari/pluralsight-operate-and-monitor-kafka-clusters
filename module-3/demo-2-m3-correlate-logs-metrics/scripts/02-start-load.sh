#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$DIR/00-env.sh"

# Producer Load Generator

DURATION_SEC="${DURATION_SEC:-150}"
TARGET_RPS="${TARGET_RPS:-50000}"
RECORD_SIZE="${RECORD_SIZE:-200}"
WINDOW_SEC="${WINDOW_SEC:-5}"

BOLD=$'\033[1m'; RESET=$'\033[0m'; DIM=$'\033[2m'
CYAN=$'\033[36m'; GREEN=$'\033[32m'; RED=$'\033[31m'; YELLOW=$'\033[33m'

hr() { printf '%s\n' "--------------------------------------------------------------------------------"; }

WARN_LOG="/tmp/ops-demo-producer.warn"
WINDOWS=$(( DURATION_SEC / WINDOW_SEC ))
[[ $WINDOWS -lt 1 ]] && WINDOWS=1

printf "%b\n" "${CYAN}${BOLD}🚀 Start Producer Load${RESET}"
hr
printf "📌 Topic:      %s\n" "$TOPIC"
printf "🛰️ Bootstrap:  %s\n" "$BOOTSTRAP"
printf "🎯 Target:     ${GREEN}${BOLD}~${TARGET_RPS} msg/s${RESET}"
printf "\n⏱️ Duration:   ~${DURATION_SEC}s (${WINDOWS} windows of ${WINDOW_SEC}s)"
printf "\n🪵 Warn log:   ${DIM}%s${RESET}\n" "$WARN_LOG"
hr

for i in $(seq 1 "$WINDOWS"); do
  window_records=$(( TARGET_RPS * WINDOW_SEC ))

  printf "\n📦 Window ${i}/${WINDOWS}  ${DIM}start=$(date +%T)${RESET}\n"

  docker exec "$BROKER_CONTAINER" bash -c "
    set -euo pipefail
    env -u JMX_PORT -u KAFKA_JMX_PORT -u KAFKA_JMX_OPTS -u JAVA_TOOL_OPTIONS -u KAFKA_OPTS \
      kafka-producer-perf-test \
        --topic '$TOPIC' \
        --num-records '$window_records' \
        --record-size '$RECORD_SIZE' \
        --throughput '$TARGET_RPS' \
        --producer-props bootstrap.servers='$BOOTSTRAP' acks=1 linger.ms=5 batch.size=65536 request.timeout.ms=3000 delivery.timeout.ms=5000 max.block.ms=3000 \
      2>>'$WARN_LOG' | grep -E 'records sent|MB/sec|avg latency|99th' | tail -n 1
  " || {
    echo -e "${RED}[producer] ❌ window failed. Check: docker exec $BROKER_CONTAINER tail -n 20 $WARN_LOG${RESET}"
    exit 1
  }
done

printf "%b\n" "\n${GREEN}${BOLD}[OK] ✅ Producer load complete${RESET}"
