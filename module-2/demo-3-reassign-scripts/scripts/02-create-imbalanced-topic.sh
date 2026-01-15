#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/00-env.sh"

h1 "STEP 1 (Terminal A): Create Intentionally Imbalanced Topic"
hr
printf "%b\n" "${DIM}Goal: all partitions use brokers 1 and 2 only, so broker3 has 0 replicas${RESET}"
hr

# Delete if exists (idempotent for recording)
docker exec "$BROKER_CONTAINER" bash -lc "
  $KAFKA_ENV_FIX
  kafka-topics --bootstrap-server $BOOTSTRAP --topic $TOPIC --delete --if-exists >/dev/null 2>&1 || true
" >/dev/null

# Wait until topic is gone (delete is async)
for i in {1..60}; do
  if ! docker exec "$BROKER_CONTAINER" bash -lc "$KAFKA_ENV_FIX kafka-topics --bootstrap-server $BOOTSTRAP --topic $TOPIC --describe >/dev/null 2>&1"; then
    break
  fi
  sleep 1
done

# Create with explicit replica assignment (6 partitions implied by 6 entries)
docker exec "$BROKER_CONTAINER" bash -lc "
  $KAFKA_ENV_FIX
  kafka-topics --bootstrap-server $BOOTSTRAP \
    --create --topic $TOPIC \
    --replica-assignment 1:2,1:2,1:2,1:2,1:2,1:2 \
    --config min.insync.replicas=2
" >/dev/null

ok "Created topic $TOPIC with replicas only on brokers 1 and 2"
warn "Next: run ./scripts/03-describe-topic.sh and call out that broker3 has 0 replicas"
