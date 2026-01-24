#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/00-env.sh"

BROKER_CONTAINER="${BROKER_CONTAINER:-broker1}"
BOOTSTRAP="${BOOTSTRAP_SERVERS:-broker1:9092}"

WINDOW_SEC="${WINDOW_SEC:-5}"
WINDOWS="${WINDOWS:-30}"
THROUGHPUT="${THROUGHPUT:-25000}"
RECORD_SIZE="${RECORD_SIZE:-200}"

WARN_LOG="/tmp/ops-demo-producer.warn"

# NEW: local stop flag (host side). Recovery will create this.
STOP_FILE="${STOP_FILE:-/tmp/ops-demo-stop-load}"
# If a previous recovery left the stop file behind, remove it so load can start.
rm -f "$STOP_FILE" >/dev/null 2>&1 || true


RED=$'\033[31m'; GREEN=$'\033[32m'; CYAN=$'\033[36m'; BOLD=$'\033[1m'; RESET=$'\033[0m'; DIM=$'\033[2m'; YELLOW=$'\033[33m'
hr(){ printf '%s\n' "--------------------------------------------------------------------------------"; }
die(){ echo -e "${RED}[ERR]${RESET} $*" >&2; exit 1; }

records_per_window=$((THROUGHPUT * WINDOW_SEC))

echo -e "${CYAN}${BOLD}🚀 Start Producer Load${RESET}"
hr
printf "📌 Topic:      %s\n" "$TOPIC"
printf "🛰️ Bootstrap:  %s\n" "$BOOTSTRAP"
printf "🎯 Target:     ~%s msg/s\n" "$THROUGHPUT"
printf "⏱️  Duration:   ~%ss (%s windows of %ss)\n" "$((WINDOW_SEC*WINDOWS))" "$WINDOWS" "$WINDOW_SEC"
printf "🪵 Warn log:   %s (inside %s)\n" "$WARN_LOG" "$BROKER_CONTAINER"
printf "🛑 Stop file:  %s (host). Create it to stop safely.\n" "$STOP_FILE"
hr

docker exec "$BROKER_CONTAINER" bash -lc "kafka-broker-api-versions --bootstrap-server '$BOOTSTRAP' >/dev/null 2>&1" \
  || die "Kafka is not reachable on $BOOTSTRAP"

docker exec "$BROKER_CONTAINER" bash -lc "kafka-topics --bootstrap-server '$BOOTSTRAP' --topic '$TOPIC' --describe >/dev/null 2>&1" \
  || die "Topic '$TOPIC' not found. Run: ./scripts/01-create-topic.sh"

docker exec "$BROKER_CONTAINER" bash -lc ": > '$WARN_LOG'"

for w in $(seq 1 "$WINDOWS"); do
  # NEW: stop requested?
  if [[ -f "$STOP_FILE" ]]; then
    rm -f "$STOP_FILE" || true
    echo -e "${YELLOW}🛑 Stop requested. Ending load cleanly.${RESET}"
    echo -e "${GREEN}✅ Load stopped.${RESET}"
    exit 0
  fi

  ts="$(date +%H:%M:%S)"
  echo -e "${DIM}📦 Window ${w}/${WINDOWS}  start=${ts}${RESET}"

  out="$(
    docker exec "$BROKER_CONTAINER" bash -lc "
      kafka-producer-perf-test \
        --topic '$TOPIC' \
        --num-records '$records_per_window' \
        --record-size '$RECORD_SIZE' \
        --throughput '$THROUGHPUT' \
        --producer-props bootstrap.servers='$BOOTSTRAP' acks=all linger.ms=0 batch.size=0 \
        2>>'$WARN_LOG' | tail -n 1
    " || true
  )"

  # If the perf test got killed because we requested stop, exit cleanly.
  if [[ -z "${out// /}" ]]; then
    if [[ -f "$STOP_FILE" ]]; then
      rm -f "$STOP_FILE" || true
      echo -e "${YELLOW}🛑 Load interrupted (stop requested).${RESET}"
      echo -e "${GREEN}✅ Load stopped.${RESET}"
      exit 0
    fi

    echo -e "${RED}[producer] ✗ window failed. Check:${RESET}"
    echo "docker exec $BROKER_CONTAINER tail -n 30 $WARN_LOG"
    exit 1
  fi

  echo "$out"
done

echo -e "${GREEN}✅ Load complete.${RESET}"
