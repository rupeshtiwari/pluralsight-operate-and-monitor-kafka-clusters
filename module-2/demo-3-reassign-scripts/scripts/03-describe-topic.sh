#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/00-env.sh"

h1 "STEP 2 (Terminal A): Topic Placement Snapshot"
hr
printf "%b\n" "${DIM}Terminal A = placement proof (before + after)${RESET}"
hr

out="$(docker exec "$BROKER_CONTAINER" bash -lc "
  $KAFKA_ENV_FIX
  kafka-topics --bootstrap-server $BOOTSTRAP --describe --topic $TOPIC
")"

# Fail fast if topic missing
if ! printf "%s\n" "$out" | grep -q "Topic: $TOPIC"; then
  fail "Topic '$TOPIC' not found. Run ./scripts/02-create-imbalanced-topic.sh first."
fi

# ---- Pretty, narrow header (one property per line) ----
topic_header="$(printf "%s\n" "$out" | head -n 1)"

# Extract "Topic: <name>" safely (the first tab-separated field)
topic_name="$(echo "$topic_header" | awk -F'\t' '{print $1}')"
rest="$(echo "$topic_header" | awk -F'\t' '{$1=""; sub(/^\t/,""); print}')"

printf "%b\n" "${MAGENTA}${BOLD}${topic_name}${RESET}"

# Break the remaining properties into multiple lines
# Example rest:
# TopicId: xxx PartitionCount: 6 ReplicationFactor: 2 Configs: min.insync.replicas=2
echo "$rest" \
  | sed -E 's/[[:space:]]+(TopicId:|PartitionCount:|ReplicationFactor:|Configs:)/\n\1/g' \
  | while IFS= read -r line; do
      [[ -z "${line// /}" ]] && continue
      printf "%b\n" "${MAGENTA}${BOLD}${line}${RESET}"
    done

hr

# ---- Parse partition rows into TSV: topic, partition, leader, replicas, isr ----
tsv_rows="$(
  printf "%s\n" "$out" | awk '
    BEGIN { OFS="\t" }
    # Match ANY line that contains Topic: and Partition: (handles leading spaces / formatting differences)
    ($0 ~ /Topic:/ && $0 ~ /Partition:/) {
      topic=""; part=""; leader=""; reps=""; isr="";
      for (i=1; i<=NF; i++) {
        if ($i=="Topic:")      topic=$(i+1)
        if ($i=="Partition:")  part=$(i+1)
        if ($i=="Leader:")     leader=$(i+1)
        if ($i=="Replicas:")   reps=$(i+1)
        if ($i=="Isr:" || $i=="ISR:") isr=$(i+1)
      }
      if (topic!="" && part!="") print topic, part, leader, reps, isr
    }
  '
)"

if [[ -z "${tsv_rows// /}" ]]; then
  # Print first few lines for quick debugging but keep it readable
  printf "%b\n" "${RED}${BOLD}ERROR:${RESET} Could not parse kafka-topics output."
  printf "%b\n" "${DIM}First 8 lines of raw output:${RESET}"
  printf "%s\n" "$out" | head -n 8
  exit 1
fi

# ---- Display table ----
printf "%b\n" "${BOLD}${BLUE}Topic  Partition  Leader  Replicas  ISR${RESET}"
echo "$tsv_rows" | column -t -s $'\t'
hr

# ---- Leader count by broker ----
printf "%b\n" "${BOLD}${CYAN}Leader count by broker:${RESET}"
echo "$tsv_rows" | awk -F'\t' '{c[$3]++} END {for (b in c) printf "  broker%s: %d leaders\n", b, c[b]}' | sort -V
printf "\n"

# ---- Replica participation by broker ----
printf "%b\n" "${BOLD}${CYAN}Replica participation by broker:${RESET}"
replica_counts="$(
  echo "$tsv_rows" | awk -F'\t' '
    {
      n = split($4, a, ",");
      for (i=1; i<=n; i++) c[a[i]]++
    }
    END { for (b in c) printf "%s\t%d\n", b, c[b] }
  ' | sort -V
)"
echo "$replica_counts" | awk -F'\t' '{printf "  broker%s: %d replicas\n", $1, $2}'
printf "\n"

# ---- One clean proof line (this is what you narrate) ----
b3="$(echo "$replica_counts" | awk -F'\t' '$1=="3"{print $2}')"
b3="${b3:-0}"
if [[ "$b3" -eq 0 ]]; then
  warn "Proof of imbalance: broker3 = 0 replicas"
else
  warn "Proof of rebalance: broker3 = ${b3} replicas"
fi
