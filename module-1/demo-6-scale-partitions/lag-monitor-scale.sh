#!/usr/bin/env bash

GROUP="scale-demo-group"

while true; do
  clear

  docker exec broker1 kafka-consumer-groups \
    --bootstrap-server broker1:9092 \
    --describe --group "$GROUP" 2>/dev/null |
  awk '
    BEGIN {
      cyan  = "\033[1;36m"
      ok    = "\033[1;32m"
      warn  = "\033[1;33m"
      bad   = "\033[1;31m"
      reset = "\033[0m"
      rows  = 0
    }

    NR <= 2 { next }

    NR == 3 {
      printf "%s%-28s %-28s %-6s %-8s %-8s %s%-8s%s\n",
             cyan, "GROUP", "TOPIC", "PART", "CURR", "LOG-END",
             bad, "LAG", reset
      print "-------------------------------------------------------------------------------------------"
      next
    }

    {
      rows++
      group=$1
      topic=$2
      part=$3
      curr=$4
      lend=$5
      lag=$6+0

      if (lag == 0)          color = ok
      else if (lag < 50000)  color = warn
      else                   color = bad

      printf "%-28s %-28s %-6s %-8s %-8s %s%-8s%s\n",
             group, topic, part, curr, lend, color, lag, reset
    }

    END {
      if (rows == 0) {
        print cyan "No partitions currently tracked for this consumer group. Start the consumer and producer to see lag." reset
      }
    }'

  sleep 3
done
