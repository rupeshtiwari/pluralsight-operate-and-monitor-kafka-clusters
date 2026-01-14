#!/usr/bin/env bash
set -euo pipefail

EXEC_CONTAINER="broker1"
BROKERS=(broker1 broker2 broker3)
JMX_PORT="9999"

REQUESTS=("Produce" "FetchConsumer" "Metadata")

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
echo "=== Request Latency (JMX) ==="
echo "kafka.network:type=RequestMetrics,name=TotalTimeMs,request=..."

for b in "${BROKERS[@]}"; do
  URL="$(jmx_url "$b")"
  echo ""
  echo "--- ${b} ---"

  for r in "${REQUESTS[@]}"; do
    OBJ="kafka.network:type=RequestMetrics,name=TotalTimeMs,request=${r}"

    echo ""
    echo "${r}: Mean"
    jmx_get "$URL" "$OBJ" "Mean"

    echo "${r}: 99thPercentile"
    jmx_get "$URL" "$OBJ" "99thPercentile"

    echo "${r}: Count"
    jmx_get "$URL" "$OBJ" "Count"
  done
done
