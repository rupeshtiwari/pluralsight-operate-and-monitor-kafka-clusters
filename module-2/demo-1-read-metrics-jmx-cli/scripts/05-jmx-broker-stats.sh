#!/usr/bin/env bash
set -euo pipefail

JMX_URL="service:jmx:rmi:///jndi/rmi://localhost:9999/jmxrmi"

run_jmx() {
  docker exec broker1 bash -lc "
    unset JMX_PORT KAFKA_JMX_PORT KAFKA_JMX_OPTS;
    kafka-run-class kafka.tools.JmxTool \
      --jmx-url ${JMX_URL} \
      --object-name \"$1\" \
      --attributes $2 \
      --one-time true
  " 2>/dev/null | grep -vE 'WARNING:|Trying to connect|deprecated' || true
}

# 1) Controller sanity
echo "Controller sanity (ActiveControllerCount):"
out="$(run_jmx "kafka.controller:type=KafkaController,name=ActiveControllerCount" "Value")"
echo "$out" | tail -n 1

echo ""
# 2) Broker pressure signal: Request queue size (network processors)
echo "Broker pressure (RequestQueueSize):"
out="$(run_jmx "kafka.network:type=RequestChannel,name=RequestQueueSize" "Value")"
echo "$out" | tail -n 1