#!/usr/bin/env bash
set -euo pipefail

JMX_URL="service:jmx:rmi:///jndi/rmi://localhost:9999/jmxrmi"

get_mean() {
  local req="$1"
  local out
  out="$(
    docker exec broker1 bash -lc "
      unset JMX_PORT KAFKA_JMX_PORT KAFKA_JMX_OPTS;
      kafka-run-class kafka.tools.JmxTool \
        --jmx-url ${JMX_URL} \
        --object-name kafka.network:type=RequestMetrics,name=TotalTimeMs,request=${req} \
        --attributes Mean \
        --one-time true
    " 2>/dev/null | grep -vE 'WARNING:|Trying to connect|deprecated' || true
  )"
  echo "$out" | tail -n 1 | awk -F, '{print $2}'
}

echo "Produce latency Mean (ms): $(get_mean Produce)"
echo "FetchConsumer latency Mean (ms): $(get_mean FetchConsumer)"