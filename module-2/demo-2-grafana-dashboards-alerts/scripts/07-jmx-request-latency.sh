#!/usr/bin/env bash
set -euo pipefail

JMX_URL="service:jmx:rmi:///jndi/rmi://broker1:9999/jmxrmi"

echo ""
echo "Produce latency Mean (ms):"
docker exec broker1 bash -lc "
  unset JMX_PORT KAFKA_JMX_PORT KAFKA_JMX_OPTS;
  kafka-run-class kafka.tools.JmxTool --jmx-url '$JMX_URL' \
    --object-name 'kafka.network:type=RequestMetrics,name=TotalTimeMs,request=Produce' \
    --attributes Mean
" | tail -n 2

echo ""
echo "FetchConsumer latency Mean (ms):"
docker exec broker1 bash -lc "
  unset JMX_PORT KAFKA_JMX_PORT KAFKA_JMX_OPTS;
  kafka-run-class kafka.tools.JmxTool --jmx-url '$JMX_URL' \
    --object-name 'kafka.network:type=RequestMetrics,name=TotalTimeMs,request=FetchConsumer' \
    --attributes Mean
" | tail -n 2

echo ""
echo "FetchFollower latency Mean (ms):"
docker exec broker1 bash -lc "
  unset JMX_PORT KAFKA_JMX_PORT KAFKA_JMX_OPTS;
  kafka-run-class kafka.tools.JmxTool --jmx-url '$JMX_URL' \
    --object-name 'kafka.network:type=RequestMetrics,name=TotalTimeMs,request=FetchFollower' \
    --attributes Mean
" | tail -n 2

echo ""
