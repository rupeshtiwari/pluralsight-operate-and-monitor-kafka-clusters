#!/usr/bin/env bash
set -euo pipefail

echo "⚠️  WARNING: This will REMOVE all Docker containers, networks, and volumes."
sleep 2

# Force Docker Desktop context on Mac (safe even if already set)
if docker context ls >/dev/null 2>&1; then
  docker context use desktop-linux >/dev/null 2>&1 || true
fi

# Basic daemon sanity check without timeout (fast fail)
if ! docker info >/dev/null 2>&1; then
  echo "❌ Docker CLI cannot talk to the daemon."
  echo "✅ Fix: Open Docker Desktop and wait until it says 'Running', then rerun."
  echo "   Also run: docker context show  (should be desktop-linux)"
  exit 1
fi

echo "🛑 Stopping all running containers..."
running="$(docker ps -q || true)"
if [[ -n "${running}" ]]; then
  docker stop -t 2 ${running} >/dev/null 2>&1 || true
  still="$(docker ps -q || true)"
  if [[ -n "${still}" ]]; then
    echo "💥 Some containers refused to stop. Killing..."
    docker kill ${still} >/dev/null 2>&1 || true
  fi
fi

echo "🧹 Removing all containers..."
allc="$(docker ps -aq || true)"
if [[ -n "${allc}" ]]; then
  docker rm -f ${allc} >/dev/null 2>&1 || true
fi

echo "🌐 Removing user-defined networks..."
docker network prune -f >/dev/null 2>&1 || true

echo "💾 Removing volumes..."
docker volume prune -f >/dev/null 2>&1 || true

echo "🧽 Removing dangling images..."
docker image prune -f >/dev/null 2>&1 || true

echo "✅ Clean slate done."


## chmod +x nuke-docker.sh

## ./nuke-docker.sh
