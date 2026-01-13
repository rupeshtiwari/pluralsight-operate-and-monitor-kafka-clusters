#!/usr/bin/env bash
set -euo pipefail

TOPIC="ops-demo-observability"
GROUP="ops-demo-cg"

echo ""
echo "Lag Snapshot (group=$GROUP, topic=$TOPIC)"
echo "--------------------------------------------------------------------"

# If group doesn't exist yet, kafka-consumer-groups exits non-zero. Make it demo-friendly.
docker exec broker1 bash -lc "
  unset JMX_PORT KAFKA_JMX_PORT KAFKA_JMX_OPTS;
  kafka-consumer-groups --bootstrap-server broker1:9092 --describe --group $GROUP 2>/dev/null \
  | awk 'NR==1 || \$1==\"$TOPIC\" {print}'
" || {
  echo "Group not found yet (expected before consumer starts)."
  exit 0
}

echo "--------------------------------------------------------------------"
echo ""
