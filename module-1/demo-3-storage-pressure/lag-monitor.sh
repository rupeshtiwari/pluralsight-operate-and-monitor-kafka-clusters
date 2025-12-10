#!/usr/bin/env bash

while true; do
  clear

  docker exec broker1 kafka-consumer-groups \
    --bootstrap-server broker1:9092 \
    --describe --group storage-pressure-group 2>/dev/null |
  awk '
    BEGIN {
      cyan  = "\033[1;36m"
      ok    = "\033[1;32m"
      warn  = "\033[1;33m"
      bad   = "\033[1;31m"
      reset = "\033[0m"

      gwidth = 22   # GROUP column width
      twidth = 22   # TOPIC column width
      cwidth = 18   # CONSUMER-ID width
    }

    # skip first 2 lines from kafka output
    NR <= 2 { next }

    NR == 3 {
      # Print header – LAG in red
      printf "%s%-" gwidth "s %-" twidth "s %-5s %-8s %-8s %s%-8s%s %-" cwidth "s\n",
             cyan, "GROUP", "TOPIC", "PART", "CURR", "LOG-END",
             bad, "LAG", reset, "CONSUMER-ID"
      print "----------------------------------------------------------------------------------------------------"
      next
    }

    {
      group=$1; topic=$2; part=$3; curr=$4; lend=$5; lag=$6; cid=$7

      # truncate if too long so columns never wrap
      if (length(group) > gwidth) group = substr(group, 1, gwidth-1)
      if (length(topic) > twidth) topic = substr(topic, 1, twidth-1)
      if (length(cid)   > cwidth) cid   = substr(cid,   1, cwidth-1)

      # choose color based on lag value
      if (lag+0 == 0)         color=ok
      else if (lag+0 < 50000) color=warn
      else                    color=bad

      printf "%-" gwidth "s %-" twidth "s %-5s %-8s %-8s %s%-8s%s %-" cwidth "s\n",
             group, topic, part, curr, lend,
             color, lag, reset, cid
    }'

  sleep 5
done
