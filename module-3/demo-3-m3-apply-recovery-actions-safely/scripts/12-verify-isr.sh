#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/00-env.sh"

REFRESH_SEC="${REFRESH_SEC:-2}"
ONCE="${1:-}"

BOLD="\033[1m"; RESET="\033[0m"; DIM="\033[2m"
GREEN="\033[32m"; YELLOW="\033[33m"; RED="\033[31m"; CYAN="\033[36m"

hr() { printf "%s\n" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; }

enter_alt_screen() { printf "\033[?1049h"; }
leave_alt_screen() { printf "\033[?1049l"; }
hide_cursor() { printf "\033[?25l"; }
show_cursor() { printf "\033[?25h"; }
cleanup() { show_cursor; leave_alt_screen; }
trap cleanup EXIT

fetch() {
  docker exec "$BROKER_CONTAINER" bash -lc "
    kafka-topics --bootstrap-server '$BOOTSTRAP_SERVERS' --topic '$TOPIC' --describe 2>/dev/null || true
  " 2>/dev/null
}

render() {
  local raw rows
  raw="$(fetch)"

  tput cup 0 0
  tput ed

  echo -e "${CYAN}${BOLD}🧩 ISR Verification${RESET} ${DIM}(topic=${TOPIC} refresh=${REFRESH_SEC}s)${RESET}"
  hr
  printf "${BOLD}%-6s %-6s %-16s %-16s %-6s${RESET}\n" "PART" "LEADR" "REPLICAS" "ISR" "URP?"
  hr

  if echo "$raw" | grep -qiE "does not exist|not found"; then
    echo -e "${YELLOW}${BOLD}⚠️  Topic not found.${RESET} Run: ./scripts/01-create-topic.sh"
    hr
    return
  fi

  rows="$(echo "$raw" | awk '
    /Partition:/ {
      part=""; leader=""; replicas=""; isr="";
      for (i=1; i<=NF; i++) {
        if ($i=="Partition:") part=$(i+1);
        if ($i=="Leader:") leader=$(i+1);
        if ($i=="Replicas:") replicas=$(i+1);
        if ($i=="Isr:") isr=$(i+1);
      }
      if (part!="") printf "%s %s %s %s\n", part, leader, replicas, isr;
    }
  ')"

  if [[ -z "${rows// /}" ]]; then
    echo -e "${YELLOW}${BOLD}⚠️  No partition data yet.${RESET}"
    hr
    return
  fi

  echo "$rows" | while read -r part leader replicas isr; do
    rep_cnt="$(echo "$replicas" | awk -F',' '{print NF}')"
    isr_cnt="$(echo "$isr" | awk -F',' '{print NF}')"

    if [[ "$isr_cnt" -lt "$rep_cnt" ]]; then
      urp="YES"; c="$RED"
    else
      urp="NO"; c="$GREEN"
    fi

    printf "%-6s %-6s %-16s %-16s ${c}%-6s${RESET}\n" "$part" "$leader" "$replicas" "$isr" "$urp"
  done

  hr
  echo -e "${DIM}Teaching:${RESET} URP=YES means replicas fell out of ISR (riskier writes)."
}

if [[ "$ONCE" == "--once" ]]; then
  render
  exit 0
fi

enter_alt_screen
hide_cursor
while true; do
  render
  sleep "$REFRESH_SEC"
done
