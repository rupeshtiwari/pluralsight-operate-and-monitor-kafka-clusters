#!/usr/bin/env bash
set -e

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$HERE/99-ui.sh"

TOPIC="${TOPIC:-ops-demo-reassign-v1}"
GROUP="${GROUP:-ops-demo-monitor-group}"
BROKER="${BROKER:-broker1:9092}"
REFRESH_SEC="${REFRESH_SEC:-2}"

WARN_LAG="${WARN_LAG:-100}"
CRIT_LAG="${CRIT_LAG:-1000}"

print_once() {
  # Get consumer group describe output
  local raw
  raw="$(docker exec broker1 bash -lc "kafka-consumer-groups --bootstrap-server '$BROKER' --group '$GROUP' --describe 2>/dev/null" || true)"

  # If no output, do NOT clear screen (prevents flashing)
  if [ -z "${raw}" ]; then
    # Print warning only once per run
    if [ "${NO_ROWS_SHOWN:-0}" -eq 0 ]; then
      export NO_ROWS_SHOWN=1
      title "CONSUMER LAG (post-scale verification)"
      kv "Topic" "$TOPIC"
      kv "Group" "$GROUP"
      kv "Refresh" "${REFRESH_SEC}s"
      printf "\n"
      warn "No consumer-group output yet"
      warn "This means: no committed offsets yet (or consumer not running)"
      printf "\n"
      info "Fix: run ./start-load.sh once to generate messages, then lag rows will appear"
      printf "\n"
    fi
    return 0
  fi

  # We have output, now it's OK to clear and redraw
  unset NO_ROWS_SHOWN
  clear
  title "CONSUMER LAG (post-scale verification)"
  kv "Topic" "$TOPIC"
  kv "Group" "$GROUP"
  kv "Refresh" "${REFRESH_SEC}s"
  printf "\n"

  printf "${BOLD}%-26s %-10s %-14s %-14s %-8s${RESET}\n" "Topic" "Partition" "Current" "Log end" "Lag"
  hr

  echo "$raw" | awk 'BEGIN{OFS="\t"} NR>1 && $1!="" {print $1,$2,$3,$4,$5}' | while IFS=$'\t' read -r t p cur end lag; do
    [ -z "$t" ] && continue
    cur="${cur:--}"
    end="${end:--}"
    lag="${lag:--}"

    local lag_fmt
    lag_fmt="$(lag_color "$lag" "$WARN_LAG" "$CRIT_LAG")"

    printf "%-26s %-10s %-14s %-14s %b\n" "$t" "$p" "$cur" "$end" "$lag_fmt"
  done
}


while true; do
  print_once
  sleep "$REFRESH_SEC"
done
