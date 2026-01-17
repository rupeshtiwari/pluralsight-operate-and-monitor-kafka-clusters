#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/99-ui.sh"

REFRESH_SEC="${REFRESH_SEC:-2}"

fmt_row() {
  local name="$1" cpu="$2" mem="$3" net="$4" blk="$5"

  # CPU threshold coloring
  local cpu_num
  cpu_num="${cpu%%%}"
  local cpu_color="$GREEN"
  if [[ "$cpu_num" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
    # >=70 red, >=30 yellow
    awk -v v="$cpu_num" 'BEGIN{ exit !(v>=70) }' && cpu_color="$RED" || true
    if [ "$cpu_color" != "$RED" ]; then
      awk -v v="$cpu_num" 'BEGIN{ exit !(v>=30) }' && cpu_color="$YELLOW" || true
    fi
  else
    cpu_color="$DIM"
  fi

  printf "%-8s  ${cpu_color}%-8s${RESET}  %-12s  %-18s  %-18s\n" "$name" "$cpu" "$mem" "$net" "$blk"
}

hide_cursor() { printf "\033[?25l"; }
show_cursor() { printf "\033[?25h"; }
trap show_cursor EXIT

hide_cursor
while true; do
  printf "\033[H\033[J"
  echo
  echo -e "${CYAN}${BOLD}Broker Load (Docker Stats)${RESET} ${DIM}(refresh=${REFRESH_SEC}s)${RESET}"
  hr
  printf "${BOLD}%-8s  %-8s  %-12s  %-18s  %-18s${RESET}\n" "BROKER" "CPU" "MEM" "NET I/O" "BLOCK I/O"
  hr

  # name,cpu,mem,net,blk
  docker stats --no-stream --format '{{.Name}} {{.CPUPerc}} {{.MemUsage}} {{.NetIO}} {{.BlockIO}}' broker1 broker2 broker3 |
    while read -r name cpu mem net blk; do
      fmt_row "$name" "$cpu" "$mem" "$net" "$blk"
    done

  hr
  echo -e "${DIM}Interpretation:${RESET} if lag grows but CPU stays modest and NET/BLOCK are stable, suspect consumer throughput, not broker saturation"
  sleep "$REFRESH_SEC"
done
