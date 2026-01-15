#!/usr/bin/env bash
set -euo pipefail

TOPIC="${TOPIC:-ops-demo-reassign-v1}"
BROKER="${BROKER:-broker1:9092}"

# Basic colors (avoid unbound vars)
BOLD="\033[1m"; RESET="\033[0m"; DIM="\033[2m"; CYAN="\033[36m"
hr(){ printf "%s\n" "────────────────────────────────────────────────────────────────────────────────"; }

echo
echo "${BOLD}LEADER DISTRIBUTION (post-scale verification)${RESET}"
hr
printf "${DIM}Topic:${RESET}             ${CYAN}%s${RESET}\n\n" "$TOPIC"

out="$(docker exec broker1 bash -lc "kafka-topics --bootstrap-server $BROKER --describe --topic $TOPIC")"

# Count leaders by broker id
counts="$(printf "%s\n" "$out" | awk '
  /Partition:/ {
    for(i=1;i<=NF;i++){
      if($i=="Leader:"){ l=$(i+1); c[l]++ }
    }
  }
  END { for (b in c) printf "%s\t%d\n", b, c[b] }
' | sort -n)"

total="$(printf "%s\n" "$counts" | awk -F'\t' '{s+=$2} END{print s+0}')"

printf "${BOLD}%-12s %-12s %-12s${RESET}\n" "Broker" "Leader count" "Share"
hr

for b in 1 2 3; do
  n="$(printf "%s\n" "$counts" | awk -F'\t' -v b="$b" '$1==b{print $2}')"
  n="${n:-0}"
  share=0
  if [[ "$total" -gt 0 ]]; then share=$(( n * 100 / total )); fi
  printf "%-12s %-12s %-12s\n" "broker${b}" "$n" "${share}%"
done

echo
printf "${DIM}Total partitions:${RESET}  ${BOLD}%s${RESET}\n" "$total"
