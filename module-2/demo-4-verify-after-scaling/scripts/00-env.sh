#!/usr/bin/env bash
set -euo pipefail

# Demo 4 focuses on verification after scaling actions.
# This topic is the same one used in Demo 3 reassignment.
TOPIC="ops-demo-reassign-v1"
GROUP="ops-demo-monitor-group"
BOOTSTRAP="broker1:9092"
BROKER_CONTAINER="broker1"

# Avoid JMX env collisions inside containers
KAFKA_ENV_FIX='unset JMX_PORT KAFKA_JMX_PORT KAFKA_JMX_OPTS;'
