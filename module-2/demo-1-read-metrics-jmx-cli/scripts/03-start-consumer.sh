#!/bin/bash

docker exec broker1 kafka-console-consumer \
  --bootstrap-server broker1:9092 \
  --topic ops-demo-metrics \
  --group ops-demo-cg \
  --from-beginning
