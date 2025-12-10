#!/usr/bin/env bash

TOPIC="scale-demo-topic-v2"

while true; do
  clear

  docker exec broker1 kafka-topics \
    --bootstrap-server broker1:9092 \
    --describe --topic "$TOPIC" 2>/dev/null |
  awk '
    BEGIN {
      cyan  = "\033[1;36m"
      green = "\033[1;32m"
      red   = "\033[1;31m"
      reset = "\033[0m"

      printf "%s%-10s %-8s %-22s %-22s%s\n",
             cyan, "PARTITION", "LEADER", "REPLICAS", "ISR", reset
      print "---------------------------------------------------------------------"
    }

    /Partition:/ {
      part = lead = repl = isr = ""

      for (i = 1; i <= NF; i++) {
        if ($i == "Partition:") part = $(i+1)
        if ($i == "Leader:")    lead = $(i+1)
        if ($i == "Replicas:")  repl = $(i+1)
        if ($i == "Isr:")       isr  = $(i+1)
      }

      nr = split(repl, rarr, ",")
      ni = split(isr,  iarr, ",")

      color = (ni < nr ? red : green)

      printf "%-10s %-8s %-22s %s%-22s%s\n",
             part, lead, repl, color, isr, reset
    }'

  sleep 5
done
