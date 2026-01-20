#!/usr/bin/env bash
set -euo pipefail

# Tail broker2 logs and highlight the lines that usually correlate with metric drops.
# Tip: keep this running while you trigger load or a broker restart.

docker logs -f broker2 2>&1 | egrep --line-buffered -i \
  'ERROR|WARN|Exception|OutOfMemory|GC|Timeout|Disconnected|Reassign|Leader|ISR|Under\-replicated|Controller|Shutdown|Starting'
