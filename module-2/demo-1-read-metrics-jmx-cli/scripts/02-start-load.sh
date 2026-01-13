#!/usr/bin/env bash
set -euo pipefail

docker exec broker1 bash -lc "
  unset JMX_PORT KAFKA_JMX_PORT KAFKA_JMX_OPTS;
  kafka-producer-perf-test \
    --topic ops-demo-metrics \
    --num-records 20000000 \
    --record-size 512 \
    --throughput 20000 \
    --producer-props bootstrap.servers=broker1:9092 acks=1 linger.ms=5 batch.size=65536
"