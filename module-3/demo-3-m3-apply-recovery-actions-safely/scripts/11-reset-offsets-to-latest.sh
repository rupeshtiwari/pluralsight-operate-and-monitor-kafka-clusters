#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/00-env.sh"

BROKER_CONTAINER="${BROKER_CONTAINER:-broker1}"
BOOTSTRAP="${BOOTSTRAP:-${BOOTSTRAP_SERVERS:-broker1:9092}}"
TOPIC="${TOPIC:-m3-correlation-topic}"
GROUP_ID="${GROUP_ID:-${GROUP:-m3-correlation-cg}}"

PID_FILE="/tmp/ops-demo-consumer.pid"
LOG_FILE="${CONSUMER_LOG:-/tmp/ops-demo-consumer.log}"

RED=$'\033[31m'; YELLOW=$'\033[33m'; GREEN=$'\033[32m'; CYAN=$'\033[36m'; BOLD=$'\033[1m'; RESET=$'\033[0m'
hr(){ printf '%s\n' "────────────────────────────────────────────────────────────────────────────"; }
die(){ echo -e "${RED}[ERR]${RESET} $*" >&2; exit 1; }

kcg() {
  docker exec "$BROKER_CONTAINER" bash -lc "
    env -u JMX_PORT -u KAFKA_JMX_PORT -u KAFKA_JMX_OPTS -u KAFKA_OPTS -u JAVA_TOOL_OPTIONS \
      kafka-consumer-groups --bootstrap-server '$BOOTSTRAP' $*
  "
}

echo -e "${YELLOW}${BOLD}⚠️ DEMO-ONLY OFFSET RESET${RESET}"
echo -e "${YELLOW}This SKIPS unprocessed messages (data loss).${RESET}"
echo
echo -e "Group: ${BOLD}$GROUP_ID${RESET}"
echo -e "Topic: ${BOLD}$TOPIC${RESET}"
echo -e "Bootstrap: ${BOLD}$BOOTSTRAP${RESET}"
hr

read -r -p "Type RESET to continue: " confirm
[[ "${confirm:-}" == "RESET" ]] || { echo "Aborted."; exit 0; }

docker inspect "$BROKER_CONTAINER" >/dev/null 2>&1 || die "Container '$BROKER_CONTAINER' not found."

hr
echo -e "${CYAN}${BOLD}Step 1) HARD stop consumer(s) (pid-file + pkill)${RESET}"

# Stop pid-file consumer
pid="$(docker exec "$BROKER_CONTAINER" bash -lc "cat '$PID_FILE' 2>/dev/null || true" | tr -d '[:space:]')"
if [[ -n "${pid:-}" ]] && docker exec "$BROKER_CONTAINER" bash -lc "kill -0 '$pid' >/dev/null 2>&1"; then
  docker exec "$BROKER_CONTAINER" bash -lc "kill '$pid' >/dev/null 2>&1 || true"
fi

# Also kill any console-consumer using this group/topic (covers stale pid files)
docker exec "$BROKER_CONTAINER" bash -lc "
  pkill -f \"kafka-console-consumer.*--group[[:space:]]+$GROUP_ID\" >/dev/null 2>&1 || true
  pkill -f \"kafka-console-consumer.*--topic[[:space:]]+$TOPIC\" >/dev/null 2>&1 || true
" >/dev/null 2>&1 || true

# Wait for group to have no active members (best-effort)
for _ in $(seq 1 20); do
  out="$(kcg "--group '$GROUP_ID' --describe" 2>/dev/null || true)"
  echo "$out" | grep -qiE "has no active members" && break
  sleep 0.5
done

echo -e "${GREEN}✅ Consumer stop requested.${RESET}"
hr

echo -e "${CYAN}${BOLD}Step 2) Reset offsets to LATEST (execute)${RESET}"
kcg "--group '$GROUP_ID' --reset-offsets --topic '$TOPIC' --to-latest --execute"

hr
echo -e "${CYAN}${BOLD}Step 3) Verify reset applied (CURRENT should be near LOG_END)${RESET}"

# Print first 50 lines for visibility
kcg "--group '$GROUP_ID' --describe" | head -n 60 || true

# Strong check: if CURRENT is still far behind LOG_END, fail loudly
raw="$(kcg "--group '$GROUP_ID' --describe" 2>/dev/null || true)"
if echo "$raw" | awk -v g="$GROUP_ID" -v t="$TOPIC" '
  $1==g && $2==t && $6 ~ /^[0-9]+$/ {
    lag=$6; if (lag>5000) bad=1
  }
  END { exit(bad?1:0) }
'; then
  echo -e "${GREEN}✅ Reset looks applied (lag small).${RESET}"
else
  echo -e "${YELLOW}⚠️ Reset did not reduce lag enough yet.${RESET}"
  echo -e "${YELLOW}Likely the consumer is still committing old offsets or group/topic mismatch.${RESET}"
  echo "Check: kcg describe output above (group=$GROUP_ID topic=$TOPIC)"
fi

hr
echo -e "${GREEN}${BOLD}Next:${RESET} run ./scripts/03-start-consumer.sh"
echo -e "${DIM}Tip:${RESET} If producer keeps running, lag may rise again immediately."
