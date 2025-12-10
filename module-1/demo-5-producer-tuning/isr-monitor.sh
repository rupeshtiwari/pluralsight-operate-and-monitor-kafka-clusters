#!/usr/bin/env bash

# Demo: Tune Producer Throughput Settings
# Focus: ISR must stay healthy while we push more throughput

while true; do
  clear

  docker exec broker1 kafka-topics \
    --bootstrap-server broker1:9092 \
    --describe --topic throughput-demo-topic 2>/dev/null |
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

      header_fmt = cyan "%-" pwidth "s %-" lwidth "s %-" rwidth "s " red "%-" iwidth "s" reset "\n"
      row_fmt    = "%-" pwidth "s %-" lwidth "s %-" rwidth "s %s%-" iwidth "s" reset "\n"
    }

    NR == 1 {
      print cyan $0 reset
      print ""
      printf header_fmt, "PARTITION", "LEADER", "REPLICAS", "ISR"
      print "--------------------------------------------------------------------------------"
      next
    }

    /Partition:/ {
      # extract values
      for (i = 1; i <= NF; i++) {
        if ($i == "Partition:") part = $(i+1)
        if ($i == "Leader:")    lead = $(i+1)
        if ($i == "Replicas:")  repl = $(i+1)
        if ($i == "Isr:")       isr  = $(i+1)
      }

      # truncate if too long
      if (length(repl) > rwidth) repl = substr(repl, 1, rwidth - 1)
      if (length(isr)  > iwidth) isr  = substr(isr, 1, iwidth - 1)

      # count ISR members
      memberCount = 1
      for (j = 1; j <= length(isr); j++) {
        if (substr(isr, j, 1) == ",") memberCount++
      }

      # color: green when full ISR (3) else red
      isrColor = (memberCount >= 3 ? green : red)

      printf row_fmt, part, lead, repl, isrColor, isr
    }'

  sleep 5
done
