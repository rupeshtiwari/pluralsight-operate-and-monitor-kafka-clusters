#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/00-env.sh"

BOLD=$'\033[1m'; RESET=$'\033[0m'
YELLOW=$'\033[33m'; GREEN=$'\033[32m'; RED=$'\033[31m'; CYAN=$'\033[36m'

printf "%b\n" "${CYAN}${BOLD}Reset Consumer Offsets to LATEST${RESET}"
printf "%b\n" "${YELLOW}${BOLD}Warning:${RESET} This skips backlog for this demo group only."
printf "%b\n\n" "Group: ${BOLD}${GROUP}${RESET}   Topic: ${BOLD}${TOPIC}${RESET}"

# Guardrails: refuse to run if group/topic doesn't match demo defaults (prevents accidents).
if [[ "$GROUP" != m3-correlation-cg || "$TOPIC" != m3-correlation-topic ]]; then
  printf "%b\n" "${RED}Refusing: GROUP/TOPIC do not match demo defaults.${RESET}"
  printf "%b\n" "Expected GROUP=m3-correlation-cg and TOPIC=m3-correlation-topic"
  exit 1
fi

# Show current offsets (short)
printf "%b\n" "${BOLD}Before:${RESET}"
docker exec "$BROKER_CONTAINER" bash -lc "kafka-consumer-groups --bootstrap-server '$BOOTSTRAP' --group '$GROUP' --describe --topic '$TOPIC' | sed -n '1,6p'" || true

printf "%b\n\n" "${BOLD}Executing reset to latest...${RESET}"
docker exec "$BROKER_CONTAINER" bash -lc "kafka-consumer-groups --bootstrap-server '$BOOTSTRAP' --group '$GROUP' --topic '$TOPIC' --reset-offsets --to-latest --execute" >/dev/null

printf "%b\n" "${GREEN}[OK] Offsets moved to latest.${RESET}"

printf "%b\n" "${BOLD}After:${RESET}"
docker exec "$BROKER_CONTAINER" bash -lc "kafka-consumer-groups --bootstrap-server '$BOOTSTRAP' --group '$GROUP' --describe --topic '$TOPIC' | sed -n '1,6p'" || true

printf "%b\n" "Tip: switch back to T1 watch-lag and you should see lag drop toward 0."
