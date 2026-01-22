#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/00-env.sh"

BOLD="\033[1m"; RESET="\033[0m"; DIM="\033[2m"
GREEN="\033[32m"; YELLOW="\033[33m"; RED="\033[31m"; CYAN="\033[36m"

hr() { printf "%s\n" "--------------------------------------------------------------------------------"; }

echo
echo -e "${CYAN}${BOLD}Create Topic${RESET}"
hr
printf "%-10s %s\n" "topic"  "$TOPIC"
printf "%-10s %s\n" "bootstrap" "$BOOTSTRAP"
printf "%-10s %s\n" "broker" "$BROKER_CONTAINER"
hr
echo

docker exec "$BROKER_CONTAINER" bash -lc "
  env -u JMX_PORT -u KAFKA_JMX_PORT -u KAFKA_JMX_OPTS -u KAFKA_JMX_OPTS -u KAFKA_OPTS -u JAVA_TOOL_OPTIONS \
    kafka-topics --bootstrap-server '$BOOTSTRAP' \
      --create --if-not-exists \
      --topic '$TOPIC' \
      --replication-factor 3 \
      --partitions 3
"

echo
echo -e "${GREEN}${BOLD}[OK] Topic ready: ${TOPIC}${RESET}"
echo
