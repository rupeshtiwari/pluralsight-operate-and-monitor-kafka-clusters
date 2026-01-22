#!/usr/bin/env bash
set -euo pipefail

docker exec broker1 bash -lc "
  unset JMX_PORT KAFKA_JMX_PORT KAFKA_JMX_OPTS;
  kafka-topics --bootstrap-server broker1:9092 \
    --create --if-not-exists \
    --topic m3-correlation-topic \
    --partitions 3 --replication-factor 3
"
