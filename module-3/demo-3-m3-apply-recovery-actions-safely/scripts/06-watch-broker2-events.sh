#!/usr/bin/env bash
set -euo pipefail

# High-signal broker2 log view for correlation with Grafana timestamps.
# Keep this running BEFORE you trigger the incident (broker2 restart).

FILTER_RE='Resigned|Controlled shutdown request|Registered broker|Starting|Started|kafka\.controller|LeaderAndIsr|become-(leader|follower)|ERROR|WARN'

printf "\nBroker2 high-signal events (Ctrl+C to stop)\n"
printf "Filter: %s\n\n" "$FILTER_RE"
printf "%-23s %-5s %s\n" "TIME" "LVL" "EVENT"
printf "%-23s %-5s %s\n" "-----------------------" "-----" "-----------------------------------------------"

docker logs -f broker2 2>&1 \
  | egrep -i "$FILTER_RE" \
  | awk '
      {
        # Typical format:
        # [2026-01-20 08:15:51,751] WARN [Producer clientId=...] Received invalid metadata...
        ts=""; lvl=""; msg=$0;
        if (match($0, /^\[[0-9\-: ,]+\]/)) {
          ts=substr($0, RSTART+1, RLENGTH-2);
        }
        if (match($0, /(INFO|WARN|ERROR)/)) {
          lvl=substr($0, RSTART, RLENGTH);
        }
        gsub(/\s+/, " ", msg);
        # Trim long noise
        if (length(msg) > 140) msg=substr(msg,1,140)"...";
        printf "%-23s %-5s %s\n", ts, lvl, msg;
        fflush();
      }
    '
