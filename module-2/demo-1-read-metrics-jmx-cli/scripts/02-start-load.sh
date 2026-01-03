#!/bin/bash

docker exec broker1 kafka-producer-perf-test \
  --topic ops-demo-metrics \
  --num-records 1000000 \
  --record-size 1024 \
  --throughput 2000 \
  --producer-props bootstrap.servers=broker1:9092
