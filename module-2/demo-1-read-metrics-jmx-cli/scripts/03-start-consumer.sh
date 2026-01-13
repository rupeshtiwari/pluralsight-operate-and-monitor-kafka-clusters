#!/usr/bin/env bash
set -euo pipefail

docker exec broker1 bash -lc "
  unset JMX_PORT KAFKA_JMX_PORT KAFKA_JMX_OPTS;
  kafka-console-consumer \
    --bootstrap-server broker1:9092 \
    --topic ops-demo-metrics \
    --group ops-demo-cg \
    --from-beginning \
    > /tmp/ops-demo-consumer.log 2>&1
"