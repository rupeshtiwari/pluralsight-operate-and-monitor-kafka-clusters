#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

export COMPOSE_FILE="$ROOT_DIR/docker-compose.yml"
export COMPOSE_PROJECT_NAME="${COMPOSE_PROJECT_NAME:-m3_demo3}"

session="m3-demo3"

tmux kill-session -t "$session" 2>/dev/null || true
docker compose down -v --remove-orphans || true

for c in zookeeper broker1 broker2 broker3 kafka-exporter prometheus grafana; do
  docker rm -f "$c" >/dev/null 2>&1 || true
done

echo "✅ Demo stopped."
