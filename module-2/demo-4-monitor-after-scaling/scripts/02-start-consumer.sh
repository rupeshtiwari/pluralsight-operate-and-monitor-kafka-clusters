#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/00-env.sh"

# Starts a consumer group so lag metrics exist.
# Run this in a dedicated terminal pane and leave it running.
# Output is offsets only (keeps the terminal readable).

docker exec -it "$BROKER_CONTAINER" bash -lc "
  $KAFKA_ENV_FIX
  kafka-console-consumer --bootstrap-server $BOOTSTRAP \
    --topic $TOPIC \
    --group $GROUP \
    --from-beginning \
    --formatter kafka.tools.DefaultMessageFormatter \
    --property print.offset=true \
    --property print.timestamp=false \
    --property print.key=false \
    --property print.value=false \
    --property print.partition=true \
    --property print.headers=false
"
