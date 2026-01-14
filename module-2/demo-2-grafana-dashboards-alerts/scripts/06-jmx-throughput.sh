#!/usr/bin/env bash
set -euo pipefail

EXEC_CONTAINER="broker1"
BROKERS=(broker1 broker2 broker3)
JMX_PORT="9999"

jmx_url() {
  local broker="$1"
  echo "service:jmx:rmi:///jndi/rmi://${broker}:${JMX_PORT}/jmxrmi"
}

jmx_get() {
  local url="$1" obj="$2" attr="$3"
  docker exec "${EXEC_CONTAINER}" bash -lc "
    unset JMX_PORT KAFKA_JMX_PORT KAFKA_JMX_OPTS;
    kafka-run-class kafka.tools.JmxTool --jmx-url '${url}' \
      --object-name '${obj}' \
      --attributes ${attr}
  " | tail -n 2
}

echo ""
echo "=== Broker Throughput (JMX) ==="
echo "BytesInPerSec / BytesOutPerSec"

for b in "${BROKERS[@]}"; do
  URL="$(jmx_url "$b")"
  echo ""
  echo "--- ${b} ---"

  echo "BytesInPerSec (OneMinuteRate):"
  jmx_get "$URL" "kafka.server:type=BrokerTopicMetrics,name=BytesInPerSec" "OneMinuteRate"

  echo "BytesInPerSec (Count):"
  jmx_get "$URL" "kafka.server:type=BrokerTopicMetrics,name=BytesInPerSec" "Count"

  echo ""
  echo "BytesOutPerSec (OneMinuteRate):"
  jmx_get "$URL" "kafka.server:type=BrokerTopicMetrics,name=BytesOutPerSec" "OneMinuteRate"

  echo "BytesOutPerSec (Count):"
  jmx_get "$URL" "kafka.server:type=BrokerTopicMetrics,name=BytesOutPerSec" "Count"
done
