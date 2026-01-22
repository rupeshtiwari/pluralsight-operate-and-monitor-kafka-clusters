#!/usr/bin/env bash
set -euo pipefail

# Controlled failure injection for correlation:
# A broker restart creates an obvious log event and a clean metric dip.

echo "Restarting broker2 (watch Grafana + broker2 logs)..."
docker restart broker2 >/dev/null

echo "✅ broker2 restart triggered."
echo "Next: watch for leader changes + ISR movement, then confirm recovery."
