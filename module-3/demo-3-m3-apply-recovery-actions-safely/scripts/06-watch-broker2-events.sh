#!/usr/bin/env bash
set -euo pipefail

PATTERN="${PATTERN:-ERROR|WARN|FATAL|Shutdown|Starting|started|KafkaServer|Controller|Becoming|Resign|Leader|ISR|UnderReplicated|Offline|ReplicaFetcher|Caught up|Epoch|Rebalance|GroupCoordinator|timeout}"

BOLD=$'\033[1m'; RESET=$'\033[0m'; CYAN=$'\033[36m'; DIM=$'\033[2m'
hr(){ printf '%s\n' "--------------------------------------------------------------------------------"; }

echo -e "${CYAN}${BOLD}📌 Watching broker2 logs (high-signal only). Ctrl+C to stop.${RESET}"
echo -e "${DIM}Pattern:${RESET} (${PATTERN})"
hr

docker logs -f broker2 2>&1 | grep --line-buffered --color=always -E "$PATTERN"
