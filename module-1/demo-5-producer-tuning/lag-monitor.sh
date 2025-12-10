#!/usr/bin/env bash

# Demo: Tune Producer Throughput Settings
# Focus: LAG changes when we change batching and linger.ms

while true; do
  clear

  docker exec broker1 kafka-consumer-groups \
    --bootstrap-server broker1:9092 \
    --describe --group tuning-demo-group 2>/dev/null |
  awk '
    BEGIN {
      cyan  = "\033[1;36m"
      ok    = "\033[1;32m"
      warn  = "\033[1;33m"
      bad   = "\033[1;31m"
      reset = "\033[0m"
    }

    NR <= 2 { next }  # skip summary lines

    NR == 3 {
      # header
      printf "%s%-28s %-28s %-6s %-8s %-8s %s%-8s%s\n",
             cyan, "GROUP", "TOPIC", "PART", "CURR", "LOG-END",
             bad, "LAG", reset

      print "-------------------------------------------------------------------------------------------"
      next
    }

    {
      group=$1
      topic=$2
      part=$3
      curr=$4
      lend=$5
      lag=$6+0   # numeric

      # lag color for this tuning demo
      if (lag == 0)        color=ok
      else if (lag < 1000) color=warn
      else                 color=bad

      printf "%-28s %-28s %-6s %-8s %-8s %s%-8s%s\n",
             group, topic, part, curr, lend,
             color, lag, reset
    }'

  sleep 3
done
