#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/99-ui.sh"
source "$DIR/00-env.sh"

title "Show Consumer Group State"

info "This proves: assigned partitions, member presence, and whether the group is stable"

docker exec "$BROKER_CONTAINER" bash -lc "$KAFKA_ENV_FIX kafka-consumer-groups --bootstrap-server '$BOOTSTRAP' --group '$GROUP' --describe" |
  sed 's/^/  /'
