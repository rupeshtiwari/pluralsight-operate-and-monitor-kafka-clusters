#!/usr/bin/env bash
set -euo pipefail

export COMPOSE_PROJECT_NAME=ps-kafka-m3-demo2
export COMPOSE_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/docker-compose.yml"
unset DOCKER_HOST DOCKER_CONTEXT COMPOSE_PROFILES

SESSION="m3-demo2"

tmux kill-session -t "$SESSION" 2>/dev/null || true

docker compose down -v --remove-orphans || true
