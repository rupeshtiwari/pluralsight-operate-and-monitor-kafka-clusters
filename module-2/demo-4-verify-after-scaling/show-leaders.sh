#!/usr/bin/env bash
set -euo pipefail

# One-time output (no watch) so the screen is calm at font size 14.
source "$(dirname "$0")/scripts/00-env.sh"
source "$(dirname "$0")/scripts/99-ui.sh"

ui_h1 "LEADER DISTRIBUTION (post-scale verification)"
ui_kv "Topic" "$TOPIC"

raw=$(docker exec "$BROKER_CONTAINER" bash -lc "$KAFKA_ENV_FIX kafka-topics --bootstrap-server $BOOTSTRAP --describe --topic $TOPIC" || true)

if [[ -z "${raw// /}" ]]; then
  printf "%b %s\n" "$(ui_tag "$RED" "ERROR")" "Topic describe returned empty output"
  exit 1
fi

# NOTE: macOS ships Bash 3.2 by default, which does NOT support associative arrays.
# So we do all counting in awk and keep this script Bash-3.2 compatible.

# Produce a simple table: brokerId count share
tmp_lines=$(echo "$raw" | awk '
  /Leader:/ {
    for (i=1; i<=NF; i++) {
      if ($i=="Leader:") { leader=$(i+1); break }
    }
    if (leader ~ /^[0-9]+$/) { c[leader]++; total++; }
  }
  END {
    for (b in c) {
      share = (total>0) ? int((c[b]/total)*100 + 0.5) : 0
      printf "%s %s %s\n", b, c[b], share
    }
    printf "__TOTAL__ %s\n", total
  }
')

total=$(echo "$tmp_lines" | awk '$1=="__TOTAL__"{print $2}')

# Determine min/max counts for a balance hint
min=$(echo "$tmp_lines" | awk '$1!="__TOTAL__"{print $2}' | sort -n | head -n 1)
max=$(echo "$tmp_lines" | awk '$1!="__TOTAL__"{print $2}' | sort -n | tail -n 1)

echo
printf "%b%-12s %-12s %-14s%b\n" "$BOLD$PURPLE" "Broker" "Leader count" "Share" "$RESET"
ui_hr

echo "$tmp_lines" \
  | awk '$1!="__TOTAL__"{print $0}' \
  | sort -n \
  | while read -r id c share; do
      color="$GREEN"
      # If noticeably imbalanced, highlight the max count in yellow
      if [[ -n "${min:-}" && -n "${max:-}" ]]; then
        diff=$((max - min))
        if (( diff >= 2 )); then
          if (( c == max )); then color="$YELLOW"; fi
        fi
      fi
      printf "%-12s %b%-12s%b %-14s\n" "broker${id}" "$BOLD$color" "$c" "$RESET" "${share}%"
    done

echo
ui_kv "Total partitions" "$total"

diff=$((max - min))
if (( diff >= 2 )); then
  printf "%b %s\n" "$(ui_tag "$YELLOW" "NOTE")" "Leader distribution is slightly uneven (max-min >= 2)"
else
  printf "%b %s\n" "$(ui_tag "$GREEN" "OK")" "Leader distribution looks balanced"
fi
