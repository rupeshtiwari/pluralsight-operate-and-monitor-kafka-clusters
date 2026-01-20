#!/usr/bin/env bash
set -euo pipefail

# Shared demo constants (override via environment if you really need to)

BOOTSTRAP="${BOOTSTRAP:-broker1:9092}"
TOPIC="${TOPIC:-m3-correlation-topic}"
GROUP="${GROUP:-m3-correlation-cg}"

# Where we write the slow-consumer log inside broker1
CONSUMER_LOG="${CONSUMER_LOG:-/tmp/ops-demo-consumer.log}"

export BOOTSTRAP TOPIC GROUP CONSUMER_LOG
