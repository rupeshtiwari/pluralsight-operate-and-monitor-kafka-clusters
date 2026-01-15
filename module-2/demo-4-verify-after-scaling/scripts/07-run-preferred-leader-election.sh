#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/00-env.sh"

# Optional: If leaders are still skewed after reassignment, run preferred leader election.
# This helps demonstrate "leaders evenly distributed".

docker exec -it "$BROKER_CONTAINER" bash -lc "
  $KAFKA_ENV_FIX
  kafka-leader-election --bootstrap-server $BOOTSTRAP --election-type PREFERRED --all-topic-partitions
"
