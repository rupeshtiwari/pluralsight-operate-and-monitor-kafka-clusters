#!/usr/bin/env bash
set -euo pipefail

JMX_URL="service:jmx:rmi:///jndi/rmi://broker1:9999/jmxrmi"

echo ""
echo "BytesInPerSec (1m rate):"
docker exec broker1 bash -lc "
  unset JMX_PORT KAFKA_JMX_PORT KAFKA_JMX_OPTS;
  kafka-run-class kafka.tools.JmxTool --jmx-url '$JMX_URL' \
    --object-name 'kafka.server:type=BrokerTopicMetrics,name=BytesInPerSec' \
    --attributes OneMinuteRate
" | tail -n 2

echo ""
echo "MessagesInPerSec (1m rate):"
docker exec broker1 bash -lc "
  unset JMX_PORT KAFKA_JMX_PORT KAFKA_JMX_OPTS;
  kafka-run-class kafka.tools.JmxTool --jmx-url '$JMX_URL' \
    --object-name 'kafka.server:type=BrokerTopicMetrics,name=MessagesInPerSec' \
    --attributes OneMinuteRate
" | tail -n 2

echo ""
