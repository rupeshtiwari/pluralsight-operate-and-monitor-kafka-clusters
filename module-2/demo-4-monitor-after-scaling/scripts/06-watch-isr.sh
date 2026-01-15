#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/00-env.sh"

# Live ISR view. Healthy means ISR includes all replicas for every partition.

watch -n 3 "docker exec $BROKER_CONTAINER bash -lc '$KAFKA_ENV_FIX kafka-topics --bootstrap-server $BOOTSTRAP --describe --topic $TOPIC | grep -E \"Partition:|Isr:\"'"
