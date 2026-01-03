#!/bin/bash

docker exec broker1 kafka-consumer-groups \
  --bootstrap-server broker1:9092 \
  --describe \
  --group ops-demo-cg
