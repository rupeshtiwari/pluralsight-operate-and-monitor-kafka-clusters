#!/usr/bin/env bash
set -euo pipefail

export COMPOSE_PROJECT_NAME=ps-kafka-m2-demo3
export COMPOSE_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/docker-compose.yml"

unset DOCKER_HOST DOCKER_CONTEXT COMPOSE_PROFILES

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$script_dir"

need() { command -v "$1" >/dev/null 2>&1 || { echo "Missing dependency: $1"; exit 1; }; }
need docker

echo "Starting containers (ZooKeeper + 3 brokers only)"
docker compose up -d --force-recreate --remove-orphans

echo "Waiting for Kafka on broker1:9092..."
for i in {1..90}; do
  if docker exec broker1 bash -lc "ps aux | grep -E '[k]afka.Kafka' >/dev/null"; then
    if docker exec broker1 bash -lc "bash -lc '</dev/tcp/localhost/9092' >/dev/null 2>&1"; then
      echo "Kafka is listening on broker1:9092"
      break
    fi
  fi
  sleep 1
done

if ! docker exec broker1 bash -lc "unset JMX_PORT KAFKA_JMX_OPTS KAFKA_JMX_PORT; kafka-topics --bootstrap-server broker1:9092 --list >/dev/null 2>&1"; then
  echo ""
  echo "ERROR: Kafka is not ready on broker1:9092. Printing broker logs."
  docker compose ps -a || true
  docker compose logs broker1 --tail=200 || true
  exit 1
fi

echo ""
echo "✅ Demo 3 is ready."
echo ""
echo "Open TWO full-screen terminals (no tmux)."
echo ""
echo "Terminal A (Topic State):"
echo "  cd '$script_dir'"
echo "  ./scripts/02-create-imbalanced-topic.sh"
echo "  ./scripts/03-describe-topic.sh"
echo "  # After reassignment completes:"
echo "  ./scripts/03-describe-topic.sh"
echo "  ./scripts/07-leader-count.sh"
echo ""
echo "Terminal B (Reassignment):"
echo "  cd '$script_dir'"
echo "  ./scripts/04-generate-plan.sh"
echo "  ./scripts/05-execute-plan.sh"
echo "  ./scripts/06-verify-plan.sh"
echo ""
