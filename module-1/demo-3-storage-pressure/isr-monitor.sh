#!/usr/bin/env bash

while true; do
  clear

  docker exec broker1 kafka-topics \
    --bootstrap-server broker1:9092 \
    --describe --topic storage-pressure-topic 2>/dev/null |
  awk '
    BEGIN {
      cyan  = "\033[1;36m"
      green = "\033[1;32m"
      red   = "\033[1;31m"
      reset = "\033[0m"

      pwidth = 10   # PARTITION
      lwidth = 8    # LEADER
      rwidth = 22   # REPLICAS
      iwidth = 22   # ISR
    }

    NR == 1 {
      # First line has topic summary, show it once at top
      print cyan $0 reset
      print ""
      # Our own header – ISR label in red
      printf "%s%-" pwidth "s %-" lwidth "s %-"
             rwidth "s %s%-" iwidth "s%s\n",
             cyan, "PARTITION", "LEADER", "REPLICAS",
             red, "ISR", reset
      print "--------------------------------------------------------------------------------"
      next
    }

    /Partition:/ {
      # Example:
      # Topic: storage-pressure-topic Partition: 0 Leader: 1 Replicas: 1,2,3 Isr: 1,2,3

      # extract fields by labels
      for (i=1; i<=NF; i++) {
        if ($i == "Partition:") part = $(i+1)
        if ($i == "Leader:")    lead = $(i+1)
        if ($i == "Replicas:")  repl = $(i+1)
        if ($i == "Isr:")       isr  = $(i+1)
      }

      # truncate long replica / ISR strings so columns never wrap
      if (length(repl) > rwidth) repl = substr(repl, 1, rwidth-1)
      if (length(isr)  > iwidth) isr  = substr(isr,  1, iwidth-1)

      # count ISR members = number of commas + 1
      memberCount = 1
      for (j=1; j<=length(isr); j++) {
        if (substr(isr,j,1) == ",") memberCount++
      }

      # choose ISR color: full replication vs degraded
      if (memberCount >= 3) isrColor = green
      else                  isrColor = red

      printf "%-" pwidth "s %-"
             lwidth "s %-"
             rwidth "s %s%-"
             iwidth "s%s\n",
             part, lead, repl, isrColor, isr, reset
    }'

  sleep 5
done
