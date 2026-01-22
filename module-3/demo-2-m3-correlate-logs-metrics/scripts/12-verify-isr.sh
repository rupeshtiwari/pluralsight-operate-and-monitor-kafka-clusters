#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$DIR/00-env.sh"

BOLD=$'\033[1m'; RESET=$'\033[0m'; DIM=$'\033[2m'
GREEN=$'\033[32m'; YELLOW=$'\033[33m'; RED=$'\033[31m'; CYAN=$'\033[36m'

hr() { printf '%s\n' "------------------------------------------------------------"; }

printf '%b\n' "${CYAN}${BOLD}Verify ISR after recovery${RESET}"
printf '%b\n' "${DIM}Topic:${RESET} $TOPIC"
hr

raw="$(docker exec "$BROKER_CONTAINER" bash -lc "kafka-topics --bootstrap-server '$BOOTSTRAP' --describe --topic '$TOPIC' 2>/dev/null || true")"

if [[ -z "${raw// /}" ]]; then
  printf '%b\n' "${RED}${BOLD}No topic output.${RESET} Is Kafka up?"
  exit 1
fi

printf '%b\n' "${BOLD}PARTITION  LEADER  REPLICAS  ISR  STATUS${RESET}"

bad=0
while read -r line; do
  [[ "$line" != *"Partition:"* ]] && continue

  p="$(awk -F'Partition: ' '{print $2}' <<<"$line" | awk '{print $1}')"
  leader="$(awk -F'Leader: ' '{print $2}' <<<"$line" | awk '{print $1}')"
  replicas="$(awk -F'Replicas: ' '{print $2}' <<<"$line" | awk '{print $1}')"
  isr="$(awk -F'Isr: ' '{print $2}' <<<"$line" | awk '{print $1}')"

  rf="$(awk -F',' '{print NF}' <<<"$replicas")"
  isr_count="$(awk -F',' '{print NF}' <<<"$isr")"

  status_color="$GREEN"
  status="OK"
  if (( isr_count < rf )); then
    status_color="$RED"
    status="ISR SHRUNK"
    bad=1
  elif (( isr_count == 1 && rf > 1 )); then
    status_color="$YELLOW"
    status="CATCHING UP"
  fi

  printf '%-9s %-7s %-8s %-4s %b%s%b\n' "$p" "$leader" "$rf" "$isr_count" "$status_color" "$status" "$RESET"
done <<<"$raw"

hr
if (( bad == 0 )); then
  printf '%b\n' "${GREEN}${BOLD}[OK] All partitions fully in-sync.${RESET}"
else
  printf '%b\n' "${RED}${BOLD}[WARN] ISR still shrunk.${RESET} Give it time or investigate broker logs + disk/network."
fi
