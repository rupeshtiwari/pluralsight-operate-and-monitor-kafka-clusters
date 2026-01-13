#!/usr/bin/env bash
set -euo pipefail

export COMPOSE_PROJECT_NAME=ps-kafka-m2-demo2
export COMPOSE_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/docker-compose.yml"
unset DOCKER_HOST DOCKER_CONTEXT COMPOSE_PROFILES

session="kafka-demo"

echo "==> stopping tmux (if any)"
tmux kill-session -t "$session" 2>/dev/null || true

echo "==> docker compose down (project: $COMPOSE_PROJECT_NAME)"
docker compose down -v --remove-orphans || true

echo "==> removing conflicting global containers by name (if any)"
for name in zookeeper broker1 broker2 broker3 prometheus grafana kafka-exporter jmx-exporter-broker1 jmx-exporter-broker2 jmx-exporter-broker3; do
  if docker ps -a --format '{{.Names}}' | grep -qx "$name"; then
    echo "  removing container: $name"
    docker rm -f "$name" >/dev/null
  fi
done

echo "==> pruning unused networks created by this project (best effort)"
# remove the compose default network if it still exists
net="${COMPOSE_PROJECT_NAME}_default"
docker network rm "$net" 2>/dev/null || true

echo "✅ Demo stopped (tmux + containers + volumes removed, conflicts cleared)."
