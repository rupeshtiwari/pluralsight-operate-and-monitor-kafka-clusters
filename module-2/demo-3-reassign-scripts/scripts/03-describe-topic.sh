#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/00-env.sh"

h1 "STEP 2 (T1): Describe Topic Placement"
hr

raw="$(docker exec "$BROKER_CONTAINER" bash -lc "
  $KAFKA_ENV_FIX
  kafka-topics --bootstrap-server $BOOTSTRAP --describe --topic $TOPIC
")"

if [[ -z "${raw// /}" ]]; then
  fail "No output returned. Topic may not exist: $TOPIC"
fi

header_line="$(printf "%s\n" "$raw" | head -n 1)"
printf "%b\n" "${BOLD}${MAGENTA}${header_line}${RESET}"
hr

printf "%b\n" "${BOLD}${BLUE}Topic${RESET}  ${BOLD}${BLUE}Partition${RESET}  ${BOLD}${BLUE}Leader${RESET}  ${BOLD}${BLUE}Replicas${RESET}  ${BOLD}${BLUE}ISR${RESET}"

printf "%s\n" "$raw" | tail -n +2 | awk '
  BEGIN { OFS="\t" }
  {
    topic=$2; gsub(/,/, "", topic)
    part=$4
    leader=$6
    replicas=$8
    isr=$10
    print topic, part, leader, replicas, isr
  }
' | column -t -s $'\t'

hr

leaders="$(printf "%s\n" "$raw" | awk -F'Leader: ' '/Leader:/{print $2}' | awk '{print $1}')"
replicas="$(printf "%s\n" "$raw" | awk -F'Replicas: ' '/Replicas:/{print $2}' | awk '{print $1}' | tr ',' '\n')"

printf "%b" "${BOLD}${CYAN}Leader count by broker:${RESET}\n"
printf "%s\n" "$leaders" | sort | uniq -c | awk '{printf "  broker%s: %s leaders\n",$2,$1}'

printf "%b\n" ""
printf "%b" "${BOLD}${CYAN}Replica participation by broker:${RESET}\n"
printf "%s\n" "$replicas" | sort | uniq -c | awk '{printf "  broker%s: %s replicas\n",$2,$1}'

printf "%b\n" ""
warn "Recording callout: Before reassignment, broker3 should show 0 replicas above"
