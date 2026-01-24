#!/usr/bin/env bash
set -euo pipefail

# Kafka bootstrap (inside Docker network)
BOOTSTRAP_SERVERS="${BOOTSTRAP_SERVERS:-broker1:9092}"
BOOTSTRAP="${BOOTSTRAP:-$BOOTSTRAP_SERVERS}"

# Topic + consumer group
TOPIC="${TOPIC:-m3-correlation-topic}"
GROUP_ID="${GROUP_ID:-m3-correlation-cg}"
GROUP="${GROUP:-$GROUP_ID}"

# Container we exec into for Kafka CLI
BROKER_CONTAINER="${BROKER_CONTAINER:-broker1}"

# Demo knobs
PARTITIONS="${PARTITIONS:-6}"
REPLICATION_FACTOR="${REPLICATION_FACTOR:-3}"
REFRESH_SEC="${REFRESH_SEC:-2}"

# Slow consumer knobs
SLEEP_MS="${SLEEP_MS:-50}"               # ms per msg
AUTO_COMMIT_MS="${AUTO_COMMIT_MS:-1000}" # commits every 1s
CONSUMER_LOG="${CONSUMER_LOG:-/tmp/ops-demo-consumer.log}"

export \
  BOOTSTRAP_SERVERS BOOTSTRAP \
  TOPIC GROUP_ID GROUP \
  BROKER_CONTAINER \
  PARTITIONS REPLICATION_FACTOR REFRESH_SEC \
  SLEEP_MS AUTO_COMMIT_MS CONSUMER_LOG
