#!/usr/bin/env bash
set -euo pipefail

GROUP="m3-correlation-cg"
TOPIC="m3-correlation-topic"

echo "⚠️  Resetting consumer group offsets for group=$GROUP topic=$TOPIC"
echo "This will set offsets to earliest for demo reset."

docker exec broker1 kafka-consumer-groups \
  --bootstrap-server broker1:9092 \
  --group "$GROUP" \
  --topic "$TOPIC" \
  --reset-offsets --to-earliest --execute

echo "✅ Reset complete. You can restart the consumer."
