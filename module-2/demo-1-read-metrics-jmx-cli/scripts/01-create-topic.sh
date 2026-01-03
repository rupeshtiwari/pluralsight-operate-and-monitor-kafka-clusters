#!/bin/bash
set -e

docker exec broker1 kafka-topics \
  --bootstrap-server broker1:9092 \
  --create \
  --topic ops-demo-metrics \
  --partitions 6 \
  --replication-factor 3
