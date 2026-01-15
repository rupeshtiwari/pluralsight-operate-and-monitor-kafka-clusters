#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/00-env.sh"

DESIRED_PARTITIONS=6
REPLICATION_FACTOR=3

# Create topic if missing
if ! docker exec "$BROKER_CONTAINER" bash -lc "$KAFKA_ENV_FIX kafka-topics --bootstrap-server $BOOTSTRAP --list | grep -x '$TOPIC'" >/dev/null 2>&1; then
  echo "Creating topic '$TOPIC' (partitions=$DESIRED_PARTITIONS, rf=$REPLICATION_FACTOR)"
  docker exec "$BROKER_CONTAINER" bash -lc "
    $KAFKA_ENV_FIX
    kafka-topics --bootstrap-server $BOOTSTRAP \
      --create --if-not-exists \
      --topic $TOPIC \
      --partitions $DESIRED_PARTITIONS \
      --replication-factor $REPLICATION_FACTOR
  "
else
  echo "Topic '$TOPIC' already exists"
fi

# Ensure partition count is at least DESIRED_PARTITIONS
current=$(docker exec "$BROKER_CONTAINER" bash -lc "$KAFKA_ENV_FIX kafka-topics --bootstrap-server $BOOTSTRAP --describe --topic $TOPIC | grep -c 'Partition:'" || echo 0)

if [[ "$current" -lt "$DESIRED_PARTITIONS" ]]; then
  echo "Altering partition count: $current -> $DESIRED_PARTITIONS"
  docker exec "$BROKER_CONTAINER" bash -lc "
    $KAFKA_ENV_FIX
    kafka-topics --bootstrap-server $BOOTSTRAP \
      --alter --topic $TOPIC --partitions $DESIRED_PARTITIONS
  "
else
  echo "Partition count OK: $current"
fi

echo "Prepared: topic=$TOPIC group=$GROUP"
