#!/usr/bin/env bash
set -euo pipefail

JMX_URL="service:jmx:rmi:///jndi/rmi://broker1:9999/jmxrmi"

echo ""
echo "Controller sanity (ActiveControllerCount):"
docker exec broker1 bash -lc "
  unset JMX_PORT KAFKA_JMX_PORT KAFKA_JMX_OPTS;
  kafka-run-class kafka.tools.JmxTool --jmx-url '$JMX_URL' \
    --object-name 'kafka.controller:type=KafkaController,name=ActiveControllerCount' \
    --attributes Value
" | tail -n 2

echo ""
echo "Broker pressure (RequestQueueSize):"
docker exec broker1 bash -lc "
  unset JMX_PORT KAFKA_JMX_PORT KAFKA_JMX_OPTS;
  kafka-run-class kafka.tools.JmxTool --jmx-url '$JMX_URL' \
    --object-name 'kafka.network:type=RequestChannel,name=RequestQueueSize' \
    --attributes Value
" | tail -n 2

echo ""
echo "Durability risk (UnderReplicatedPartitions):"
docker exec broker1 bash -lc "
  unset JMX_PORT KAFKA_JMX_PORT KAFKA_JMX_OPTS;
  kafka-run-class kafka.tools.JmxTool --jmx-url '$JMX_URL' \
    --object-name 'kafka.server:type=ReplicaManager,name=UnderReplicatedPartitions' \
    --attributes Value
" | tail -n 2

echo ""
