#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/99-ui.sh"
source "$DIR/00-env.sh"

title "Ensure Topic Exists"

info "Creating topic if missing"
docker exec "$BROKER_CONTAINER" bash -lc "$KAFKA_ENV_FIX kafka-topics --bootstrap-server '$BOOTSTRAP' --create --if-not-exists --topic '$TOPIC' --partitions 6 --replication-factor 3 >/dev/null"

ok "Topic is ready"

info "Describe topic (leaders + ISR)"
docker exec "$BROKER_CONTAINER" bash -lc "$KAFKA_ENV_FIX kafka-topics --bootstrap-server '$BOOTSTRAP' --describe --topic '$TOPIC'" |
  sed 's/^/  /'
