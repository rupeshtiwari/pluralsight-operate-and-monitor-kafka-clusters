#!/usr/bin/env bash
set -euo pipefail

echo "🔪 Killing previous slow consumer (if any)..."

docker exec broker1 bash -c "
  pkill -f 'kafka-run-class.*ConsoleConsumer' || true
"

echo "✅ Previous consumer (if any) terminated."
