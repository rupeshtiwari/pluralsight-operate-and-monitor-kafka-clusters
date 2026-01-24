#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/00-env.sh"

BROKER_CONTAINER="${BROKER_CONTAINER:-broker1}"
BOOTSTRAP="${BOOTSTRAP:-${BOOTSTRAP_SERVERS:-broker1:9092}}"
STOP_FILE="${STOP_FILE:-/tmp/ops-demo-stop-load}"

CYAN=$'\033[36m'; BOLD=$'\033[1m'; RESET=$'\033[0m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'
hr(){ printf '%s\n' "────────────────────────────────────────────────────────────────────────────"; }

echo -e "${CYAN}${BOLD}🛟 Demo Recovery + Lag Screen (recording-safe)${RESET}"
hr

echo -e "${BOLD}0) Stop producer load${RESET}"
touch "$STOP_FILE" >/dev/null 2>&1 || true
docker exec "$BROKER_CONTAINER" bash -lc "pkill -f 'kafka-producer-perf-test' >/dev/null 2>&1 || true" || true
echo -e "${GREEN}✅ Producer stop requested.${RESET}"
hr

echo -e "${BOLD}1) Stop consumer hard (so it cannot re-commit old offsets)${RESET}"
docker exec "$BROKER_CONTAINER" bash -lc "
  PID_FILE='/tmp/ops-demo-consumer.pid';
  pid=\$(cat \$PID_FILE 2>/dev/null || true);
  if [[ -n \"\$pid\" ]] && kill -0 \"\$pid\" >/dev/null 2>&1; then
    kill \"\$pid\" >/dev/null 2>&1 || true;
  fi
  pkill -f 'kafka-console-consumer' >/dev/null 2>&1 || true
" || true
echo -e "${GREEN}✅ Consumer stop requested.${RESET}"
hr

echo -e "${BOLD}2) Reset offsets to latest (skips backlog)${RESET}"
printf "RESET\n" | "$DIR/11-reset-offsets-to-latest.sh"
hr

echo -e "${BOLD}3) Start consumer again${RESET}"
"$DIR/03-start-consumer.sh" || true
hr

echo -e "${BOLD}4) Recording screen: Lag View only${RESET}"
echo -e "${GREEN}Tip:${RESET} this clears the pane so you only show lag."
sleep 1
printf "\033[2J\033[H"
RUN_FOR_SEC=15 "$DIR/10-watch-lag.sh"
hr
echo -e "${GREEN}${BOLD}Done.${RESET}"
