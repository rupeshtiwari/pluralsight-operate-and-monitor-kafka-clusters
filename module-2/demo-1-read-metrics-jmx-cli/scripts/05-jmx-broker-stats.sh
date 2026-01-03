#!/bin/bash

docker exec broker1 kafka-run-class kafka.tools.JmxTool \
  --jmx-url service:jmx:rmi:///jndi/rmi://localhost:9999/jmxrmi \
  --object-name kafka.server:type=KafkaRequestHandlerPool,name=RequestHandlerAvgIdlePercent \
  --attributes Value \
  --one-time true
