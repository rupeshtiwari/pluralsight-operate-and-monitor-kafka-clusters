#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/00-env.sh"

docker exec "$BROKER_CONTAINER" bash -lc "
  $KAFKA_ENV_FIX
  kafka-reassign-partitions --bootstrap-server $BOOTSTRAP \
    --execute --reassignment-json-file /tmp/reassign.json
"
