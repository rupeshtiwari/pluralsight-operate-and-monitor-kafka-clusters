#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/00-env.sh"

docker exec "$BROKER_CONTAINER" bash -lc "
  $KAFKA_ENV_FIX
  kafka-topics --bootstrap-server $BOOTSTRAP --describe --topic $TOPIC \
  | awk -F'Leader: ' '{print \$2}' | awk '{print \$1}' | sort | uniq -c
"
