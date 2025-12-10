#!/usr/bin/env bash

TOPIC="scale-demo-topic-v2"


while true; do
  clear

  docker exec broker1 kafka-topics \
    --bootstrap-server broker1:9092 \
    --describe --topic "$TOPIC" 2>/dev/null |
  awk '
    BEGIN {
      cyan   = "\033[1;36m"
      green  = "\033[1;32m"
      red    = "\033[1;31m"
      warn   = "\033[1;33m"
      reset  = "\033[0m"

      printf "%s%-10s %-8s %-22s %-22s%s\n",
             cyan, "PARTITION", "LEADER", "REPLICAS", "ISR", reset
      print "---------------------------------------------------------------------"

      hasRow = 0
    }

    /Partition:/ {
      hasRow = 1
      part = lead = repl = isr = ""

      for (i = 1; i <= NF; i++) {
        if ($i == "Partition:") part = $(i+1)
        if ($i == "Leader:")    lead = $(i+1)
        if ($i == "Replicas:")  repl = $(i+1)
        if ($i == "Isr:")       isr  = $(i+1)
      }

      leaderCount[lead]++

      printf "%-10s %-8s %-22s %-22s\n",
             part, lead, repl, isr
    }

    END {
      if (!hasRow) {
        print ""
        print cyan "No leader data yet for this topic. Create and scale the topic first." reset
        exit
      }

      print ""
      print cyan "Leader distribution (leaders per broker)" reset
      print "----------------------------------------"

      maxc = -1
      minc = 1e9
      for (b in leaderCount) {
        if (leaderCount[b] > maxc) maxc = leaderCount[b]
        if (leaderCount[b] < minc) minc = leaderCount[b]
      }

      imbalance = (maxc - minc > 1 ? 1 : 0)

      # only print brokers that actually appear
      for (b in leaderCount) {
        c = leaderCount[b]

        # color rules:
        #  - 0 leaders (should not happen in steady state) -> red
        #  - hotspot when imbalance and this broker has max leaders -> red
        #  - otherwise green
        color = green
        if (c == 0)                color = red
        else if (imbalance && c==maxc) color = red

        printf "broker%s: %s%d%s leaders\n", b, color, c, reset
      }
    }'

  sleep 5
done
