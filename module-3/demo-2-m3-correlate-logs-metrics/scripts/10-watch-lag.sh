#!/usr/bin/env bash
set -euo pipefail

# 2 seconds interval, 10 iterations = ~20 seconds
for i in {1..10}; do
  ./scripts/04-check-lag.sh
  sleep 2
done
