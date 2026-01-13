#!/usr/bin/env bash
set -euo pipefail

JMX_URL="service:jmx:rmi:///jndi/rmi://localhost:9999/jmxrmi"

out="$(
  docker exec broker1 bash -lc "
    unset JMX_PORT KAFKA_JMX_PORT KAFKA_JMX_OPTS;
    kafka-run-class kafka.tools.JmxTool \
      --jmx-url ${JMX_URL} \
      --object-name kafka.server:type=BrokerTopicMetrics,name=BytesInPerSec \
      --attributes OneMinuteRate \
      --one-time true
  " 2>/dev/null | grep -vE 'WARNING:|Trying to connect|deprecated' || true
)"

# output is usually: "time","...:OneMinuteRate"\n<timestamp>,<value>
value="$(echo "$out" | tail -n 1 | awk -F, '{print $2}')"
echo "BytesInPerSec (1m rate): ${value:-N/A}"