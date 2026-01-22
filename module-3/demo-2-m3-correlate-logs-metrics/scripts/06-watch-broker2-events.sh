#!/usr/bin/env bash
set -euo pipefail

# Highlighted Broker2 logs with full line width and colored levels
FILTER_RE='Controlled shutdown|Starting|Started|Registered broker|Resigned|kafka\.controller|Controller|LeaderAndIsr|UpdateMetadata|ReplicaFetcher|GroupCoordinator|Rebalance|ISR|UnderReplicated|ControllerMovedException|ERROR|WARN'

# Colors
BOLD=$'\033[1m'; RESET=$'\033[0m'; DIM=$'\033[2m'
GREEN=$'\033[32m'; YELLOW=$'\033[33m'; RED=$'\033[31m'; CYAN=$'\033[36m'

printf "\n${CYAN}${BOLD}Broker2 High-Signal Logs${RESET} ${DIM}(Ctrl+C to stop)${RESET}\n"
printf "Filter: ${DIM}${FILTER_RE}${RESET}\n\n"
printf "${BOLD}%-23s %-7s %s${RESET}\n" "TIME" "LEVEL" "EVENT"
printf "%-23s %-7s %s\n" "-----------------------" "-------" "-------------------------------------------------------------"

docker logs -f broker2 2>&1 \
  | grep -Ei "$FILTER_RE" \
  | awk -v BOLD="$BOLD" -v RESET="$RESET" -v RED="$RED" -v YELLOW="$YELLOW" -v GREEN="$GREEN" '
      {
        ts = ""; lvl = ""; msg = $0

        # Extract timestamp
        if ($1 ~ /^\[[0-9]{4}-[0-9]{2}-[0-9]{2}/) {
          ts = substr($1, 2, length($1) - 2)
          msg = substr($0, index($0, $3))
        }

        # Detect level
        if (msg ~ /INFO/) lvl = "INFO"
        else if (msg ~ /WARN/) lvl = "WARN"
        else if (msg ~ /ERROR/) lvl = "ERROR"
        else lvl = "INFO"

        # Color
        color = (lvl == "ERROR") ? RED : ((lvl == "WARN") ? YELLOW : GREEN)

        printf "%s%-23s%s %s%-7s%s %s\n", BOLD, ts, RESET, color, lvl, RESET, msg
        fflush()
      }
  '
