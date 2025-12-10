#!/usr/bin/env bash

while true; do
  clear

  docker exec broker1 kafka-consumer-groups \
    --bootstrap-server broker1:9092 \
    --describe --group durability-group 2>/dev/null |
  awk '
    BEGIN {
      cyan  = "\033[1;36m"
      ok    = "\033[1;32m"
      warn  = "\033[1;33m"
      bad   = "\033[1;31m"
      reset = "\033[0m"
    }

    # skip the very first informational line
    NR == 1 { next }

    # Kafka prints a header line that starts with GROUP
    /^GROUP/ {
      printf "%s%-24s %-24s %-4s %-8s %-8s %s%-8s%s\n",
             cyan, "GROUP", "TOPIC", "PART", "CURR", "LOG-END",
             bad, "LAG", reset
      print "----------------------------------------------------------------------------"
      next
    }

    # data rows: expect at least 6 fields
    NF >= 6 && $1 != "GROUP" {
      group = $1
      topic = $2
      part  = $3
      curr  = $4
      lend  = $5
      lag   = $6

      if (lag + 0 == 0)        color = ok
      else if (lag + 0 < 200000) color = warn
      else                     color = bad

      printf "%-24s %-24s %-4s %-8s %-8s %s%-8s%s\n",
             group, topic, part, curr, lend,
             color, lag, reset
    }
  '

  # IMPORTANT: let the screen settle and values change over time
  sleep 5
done
