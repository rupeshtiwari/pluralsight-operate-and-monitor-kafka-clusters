#!/usr/bin/env bash

while true; do
  clear

  docker exec broker1 kafka-consumer-groups \
    --bootstrap-server broker1:9092 \
    --describe --group lag-demo-group 2>/dev/null |
  awk '
    BEGIN {
      cyan  = "\033[1;36m"
      ok    = "\033[1;32m"
      warn  = "\033[1;33m"
      bad   = "\033[1;31m"
      reset = "\033[0m"
    }

    NR <= 2 { next }  # skip first 2 lines from kafka output

    NR == 3 {
      # Print header — LAG is red now
      printf "%s%-12s %-14s %-5s %-8s %-8s %s%-8s%s %-s\n",
             cyan, "GROUP", "TOPIC", "PART", "CURR", "LOG-END",
             bad, "LAG", reset, "CONSUMER-ID"
      print "--------------------------------------------------------------------------"
    }

    {
      group=$1; topic=$2; part=$3; curr=$4; lend=$5; lag=$6; cid=$7

      # choose color based on lag value
      if (lag+0 == 0)           color=ok
      else if (lag+0 < 50000)   color=warn
      else                      color=bad

      printf "%-12s %-14s %-5s %-8s %-8s %s%-8s%s %-s\n",
             group, topic, part, curr, lend,
             color, lag, reset, cid
    }'

  sleep 5
done
