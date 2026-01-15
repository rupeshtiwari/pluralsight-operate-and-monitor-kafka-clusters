#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/00-env.sh"

# Intentionally imbalanced:
# All partitions use broker1+broker2 only (broker3 unused)
docker exec "$BROKER_CONTAINER" bash -lc "
  $KAFKA_ENV_FIX
  kafka-topics --bootstrap-server $BOOTSTRAP \
    --create --if-not-exists \
    --topic $TOPIC \
    --replica-assignment 1:2,1:2,1:2,1:2,1:2,1:2
"
