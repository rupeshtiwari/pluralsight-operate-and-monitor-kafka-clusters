#!/usr/bin/env bash
set -euo pipefail

export COMPOSE_PROJECT_NAME=ps-kafka-m2-demo3
export COMPOSE_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/docker-compose.yml"
unset DOCKER_HOST DOCKER_CONTEXT COMPOSE_PROFILES

session="kafka-demo3"

echo "==> stopping tmux (if any)"
tmux kill-session -t "$session" 2>/dev/null || true

echo "==> docker compose down (project: $COMPOSE_PROJECT_NAME)"
docker compose down -v --remove-orphans || true

echo "==> removing conflicting global containers by name (if any)"
for name in zookeeper broker1 broker2 broker3; do
  if docker ps -a --format '{{.Names}}' | grep -qx "$name"; then
    echo "  removing container: $name"
    docker rm -f "$name" >/dev/null
  fi
done

echo "==> pruning demo network (best effort)"
docker network rm ps-kafka-m2-demo3-net 2>/dev/null || true

echo "✅ Demo 3 stopped (tmux + containers + volumes removed, conflicts cleared)."
