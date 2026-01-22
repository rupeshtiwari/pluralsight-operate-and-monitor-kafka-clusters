#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/00-env.sh"

echo -e "\n🔁 Restarting consumer to trigger recovery..."

# Stop any previous slow consumer if running
pkill -f start-consumer.sh || true
sleep 2

# Optionally: reset offsets if consumer is too far behind (commented by default)
# echo "⚠️ Resetting offsets to latest..."
# docker exec broker1 kafka-consumer-groups --bootstrap-server "$BOOTSTRAP" \
#   --group "$GROUP" --topic "$TOPIC" --reset-offsets --to-latest --execute || true

# Restart slow consumer
"$DIR/03-start-consumer.sh"

echo -e "✅ Consumer restarted."
