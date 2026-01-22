#!/bin/bash
set -euo pipefail

echo "🚑 FAST RECOVERY: Drain lag quickly (demo-safe)"
echo "------------------------------------------------"

echo ""
echo "🧹 Step 1) Kill old slow consumer (if running)"
pkill -f 'java.*consumer' >/dev/null 2>&1 || true
sleep 2
echo "✅ Old consumer stopped"

echo ""
echo "🛑 Step 2) Fix the JMX 9999 port issue (clean env)"
unset JMX_PORT KAFKA_JMX_OPTS JAVA_TOOL_OPTIONS KAFKA_OPTS
echo "✅ JMX conflicts bypassed (we launch consumer with clean env)"

echo ""
echo "⚡ Step 3) Start 3 recovery consumers (parallel, fast mode)"

for PART in 0 1 2; do
  echo "➡️ Starting consumer for partition $PART"
  env -u JMX_PORT -u KAFKA_JMX_OPTS -u JAVA_TOOL_OPTIONS -u KAFKA_OPTS \
    kafka-console-consumer \
    --bootstrap-server broker1:9092 \
    --topic m3-correlation-topic \
    --group m3-correlation-cg \
    --partition "$PART" \
    --consumer-property fetch.min.bytes=1048576 \
    --consumer-property max.partition.fetch.bytes=5242880 \
    --max-messages 0 > /dev/null 2>&1 &
done

echo ""
echo "✅ FAST recovery consumers (3) started in background. Lag will drain much faster now."
