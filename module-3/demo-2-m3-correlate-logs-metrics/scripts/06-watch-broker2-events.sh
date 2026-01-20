#!/usr/bin/env bash
set -euo pipefail

BROKER="broker2"

echo ""
echo "Broker2 high-signal events (filtered)"
echo "Tip: when Grafana spikes, read 1-2 lines with the same timestamp."
echo ""

# Include only incident-worthy keywords
INCLUDE='ERROR|WARN|Shutdown|Starting|started|Resigned|KafkaController|LeaderAndIsr|become-leader|become-follower|ISR|UnderReplicated|NotLeaderOrFollower|NOT_LEADER_OR_FOLLOWER|NetworkClient|Disconnected|Reconnected'

# Exclude common noise (tune this list if needed)
EXCLUDE='__consumer_offsets|ExpirationReaper|DelayedOperationPurgatory|Throttle|Throttled|Truncating partition|ReplicaAlterLogDirs|LogDirFailureHandler'

# Header
printf "%-23s %-5s %-18s %s\n" "timestamp" "lvl" "component" "message"
printf "%-23s %-5s %-18s %s\n" "-----------------------" "-----" "------------------" "------------------------------"

docker logs -f --since 10m "$BROKER" 2>&1 \
  | egrep -i "$INCLUDE" \
  | egrep -iv "$EXCLUDE" \
  | awk '{
      ts=$1; lvl=$3;
      comp=$4;
      $1=""; $2=""; $3=""; $4="";
      msg=$0;
      gsub(/^ +/,"",msg);
      printf "%-23s %-5s %-18s %s\n", ts, lvl, comp, msg;
      fflush();
    }'
