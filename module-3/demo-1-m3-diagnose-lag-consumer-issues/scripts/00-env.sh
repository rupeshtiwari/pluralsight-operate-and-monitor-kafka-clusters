#!/usr/bin/env bash
set -euo pipefail

# Module 3 Demo 1: Diagnose Lag and Consumer Issues
TOPIC="m3-demo1-lag-topic"
GROUP="m3-demo1-diagnose-group"
BOOTSTRAP="broker1:9092"
BROKER_CONTAINER="broker1"

# Producer load tuning (safe defaults)
RECORDS_PER_SEC="25000"
TOTAL_RECORDS="500000"
RECORD_SIZE_BYTES="512"

# Avoid JMX env collisions inside containers
KAFKA_ENV_FIX='unset JMX_PORT KAFKA_JMX_PORT KAFKA_JMX_OPTS KAFKA_OPTS JAVA_TOOL_OPTIONS;'
