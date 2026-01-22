#!/usr/bin/env bash
set -euo pipefail

# Shared demo constants (override via environment if you really need to)

BOOTSTRAP="${BOOTSTRAP:-broker1:9092}"
TOPIC="${TOPIC:-m3-correlation-topic}"
GROUP="${GROUP:-m3-correlation-cg}"

# Container we exec into for CLI commands
BROKER_CONTAINER="${BROKER_CONTAINER:-broker1}"

# Slow consumer sleep per message (seconds). 0.02 keeps lag measurable.
SLOW_CONSUMER_DELAY_SEC="${SLOW_CONSUMER_DELAY_SEC:-0.02}"

# Where we write the slow-consumer log inside broker1
CONSUMER_LOG="${CONSUMER_LOG:-/tmp/ops-demo-consumer.log}"

export BOOTSTRAP TOPIC GROUP BROKER_CONTAINER SLOW_CONSUMER_DELAY_SEC CONSUMER_LOG
