#!/usr/bin/env bash

# Pretty Disk Usage Monitor for Kafka Broker1

while true; do
  clear

  docker exec broker1 sh -c 'du -sh /var/lib/kafka/data 2>/dev/null' |
  awk '
    BEGIN {
      cyan   = "\033[1;36m"
      green  = "\033[1;32m"
      yellow = "\033[1;33m"
      red    = "\033[1;31m"
      reset  = "\033[0m"

      # SIZE header in RED
      printf "%s%-30s %s%-10s%s\n", cyan, "PATH", red, "SIZE", reset
      print "-----------------------------------------------"
    }

    {
      sizeStr = $1
      path    = $2

      color = green

      # Convert size to MB (approx)
      n = sizeStr
      gsub(/[^0-9.]/, "", n)
      unit = substr(sizeStr, length(sizeStr), 1)

      mb = n
      if (unit == "K")      mb = n / 1024
      else if (unit == "G") mb = n * 1024

      # Color rules
      if      (mb >= 500) color = red
      else if (mb >= 100) color = yellow

      printf "%-30s %s%-10s%s\n", path, color, sizeStr, reset
    }'

  sleep 3
done
