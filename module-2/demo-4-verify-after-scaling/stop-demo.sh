#!/usr/bin/env bash
set -euo pipefail

export COMPOSE_PROJECT_NAME=ps-kafka-m2-demo4
export COMPOSE_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/docker-compose.yml"

unset DOCKER_HOST DOCKER_CONTEXT COMPOSE_PROFILES

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$script_dir"

source "$script_dir/scripts/00-env.sh"

PID_FILE="/tmp/demo4_consumer.pid"

# Stop background consumer if present
if docker exec "$BROKER_CONTAINER" bash -lc "test -s $PID_FILE" >/dev/null 2>&1; then
  pid=$(docker exec "$BROKER_CONTAINER" bash -lc "cat $PID_FILE" || true)
  if [[ -n "${pid:-}" ]]; then
    echo "Stopping consumer (pid=$pid)"
    docker exec "$BROKER_CONTAINER" bash -lc "kill $pid >/dev/null 2>&1 || true"
  fi
  docker exec "$BROKER_CONTAINER" bash -lc "rm -f $PID_FILE" || true
fi

echo "Stopping containers"
docker compose down -v --remove-orphans
