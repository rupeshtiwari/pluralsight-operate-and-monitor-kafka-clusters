#!/bin/bash

echo "Produce latency:"
docker exec broker1 kafka-run-class kafka.tools.JmxTool \
  --jmx-url service:jmx:rmi:///jndi/rmi://localhost:9999/jmxrmi \
  --object-name kafka.network:type=RequestMetrics,name=TotalTimeMs,request=Produce \
  --attributes Mean \
  --one-time true

echo ""
echo "FetchConsumer latency:"
docker exec broker1 kafka-run-class kafka.tools.JmxTool \
  --jmx-url service:jmx:rmi:///jndi/rmi://localhost:9999/jmxrmi \
  --object-name kafka.network:type=RequestMetrics,name=TotalTimeMs,request=FetchConsumer \
  --attributes Mean \
  --one-time true
