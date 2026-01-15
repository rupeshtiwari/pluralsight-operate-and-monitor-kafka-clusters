#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/00-env.sh"

# Live view of consumer lag for the demo consumer group.
# Uses watch on the host so you can leave it running.

watch -n 2 "docker exec $BROKER_CONTAINER bash -lc '$KAFKA_ENV_FIX kafka-consumer-groups --bootstrap-server $BOOTSTRAP --group $GROUP --describe 2>/dev/null || echo group not found'"
