#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/99-ui.sh"
source "$DIR/00-env.sh"

title "Start Kafka Demo Environment"
info "Bringing up Docker Compose services"

docker compose up -d

info "Waiting for broker healthchecks"
for b in broker1 broker2 broker3; do
  printf "%s" "- $b: "
  for i in $(seq 1 60); do
    if docker inspect -f '{{json .State.Health.Status}}' "$b" 2>/dev/null | grep -q healthy; then
      ok "healthy"
      break
    fi
    if [ "$i" -eq 60 ]; then
      err "timed out"
      exit 1
    fi
    sleep 1
  done
done

ok "Kafka brokers are ready"
kv "Bootstrap" "$BOOTSTRAP"
kv "Topic" "$TOPIC"
kv "Group" "$GROUP"
