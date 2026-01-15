#!/usr/bin/env bash
set -euo pipefail

# Demo 4 (Module 2): Monitor Cluster After Scaling Actions
#
# Goal: prepare a deterministic state so the recorded demo is ONLY verification.
#
# RECORDING FLOW:
#   1) ./run-demo.sh      # prep + startup
#   2) Start recording
#   3) ./start-load.sh    # create short, controlled load
#   4) ./watch-lag.sh     # observe lag trend
#   5) ./show-leaders.sh  # confirm leader balance

export COMPOSE_PROJECT_NAME=ps-kafka-m2-demo4
export COMPOSE_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/docker-compose.yml"

unset DOCKER_HOST DOCKER_CONTEXT COMPOSE_PROFILES

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$script_dir"

# Defaults (required because we use set -u)
TOPIC="${TOPIC:-ops-demo-reassign-v1}"
GROUP="${GROUP:-ops-demo-monitor-group}"
BROKER="${BROKER:-broker1:9092}"

# shellcheck source=/dev/null
source "$script_dir/scripts/99-ui.sh"

need() { command -v "$1" >/dev/null 2>&1 || { echo "Missing dependency: $1"; exit 1; }; }
need docker

clear || true
ui_h1 "DEMO 4 PREP (deterministic startup)"

ui_tag "STEP 1"
echo "Starting containers (ZooKeeper + 3 brokers)"
docker compose up -d --force-recreate --remove-orphans >/dev/null

echo ""
ui_tag "STEP 2"
echo "Waiting for Kafka on broker1:9092"

for i in {1..120}; do
  if docker exec broker1 bash -lc "ps aux | grep -E '[k]afka.Kafka' >/dev/null"; then
    if docker exec broker1 bash -lc "bash -lc '</dev/tcp/localhost/9092' >/dev/null 2>&1"; then
      ui_ok "Kafka is listening on broker1:9092"
      break
    fi
  fi
  sleep 1
done

if ! docker exec broker1 bash -lc "unset JMX_PORT KAFKA_JMX_PORT KAFKA_JMX_OPTS; kafka-topics --bootstrap-server '$BROKER' --list >/dev/null 2>&1"; then
  echo ""
  ui_err "Kafka is not ready. Printing broker1 logs"
  docker compose ps -a || true
  docker compose logs broker1 --tail=200 || true
  exit 1
fi

echo ""
ui_tag "STEP 3"
echo "Preparing topic + consumer group (idempotent)"
./scripts/01-prepare-state.sh
./scripts/02-start-consumer-bg.sh

echo ""
ui_tag "SEED"
echo "Initializing offsets so lag table is ready (50 records)"

# Seed a few records so the consumer commits offsets (NOT load)
docker exec broker1 bash -lc "seq 1 50 | kafka-console-producer --bootstrap-server '$BROKER' --topic '$TOPIC' >/dev/null 2>&1" || true

# Wait until consumer-group describe returns rows (max ~10s)
ui_tag "WAIT"
echo "Waiting for consumer offsets to appear"
for i in {1..10}; do
  if docker exec broker1 bash -lc "kafka-consumer-groups --bootstrap-server '$BROKER' --group '$GROUP' --describe 2>/dev/null | grep -q \"^$TOPIC[[:space:]]\""; then
    ui_ok "Lag table is ready"
    break
  fi
  sleep 1
done

echo ""
ui_tag "READY"
echo "Prep complete. You are ready to record"

echo ""
ui_h1 "RECORDING COMMANDS (one terminal at a time)"
printf "  %b%s%b\n" "$BOLD" "./start-load.sh" "$RESET"
printf "  %b%s%b\n" "$BOLD" "./watch-lag.sh" "$RESET"
printf "  %b%s%b\n" "$BOLD" "./show-leaders.sh" "$RESET"
echo
