#!/usr/bin/env bash
set -euo pipefail

TOPIC="ops-demo-observability"
GROUP="ops-demo-cg"

docker exec broker1 bash -lc "
  unset JMX_PORT KAFKA_JMX_PORT KAFKA_JMX_OPTS;

  # Start consumer in background inside the container
  nohup kafka-console-consumer \
    --bootstrap-server broker1:9092 \
    --topic '$TOPIC' \
    --group '$GROUP' \
    --from-beginning \
    > /tmp/ops-demo-consumer.log 2>&1 &

  echo \"Consumer started. PID=\$!\"
  echo \"Log: /tmp/ops-demo-consumer.log\"
"
