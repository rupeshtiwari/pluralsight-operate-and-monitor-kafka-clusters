#!/usr/bin/env bash
set -euo pipefail

export COMPOSE_PROJECT_NAME=ps-kafka-m2-demo1
session="kafka-demo"

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
start_dir="$script_dir"
cd "$start_dir"

need() { command -v "$1" >/dev/null 2>&1 || { echo "Missing dependency: $1"; exit 1; }; }
need docker
need tmux

# Fail fast if Docker daemon is not reachable
if ! docker info >/dev/null 2>&1; then
  echo "ERROR: Docker daemon not reachable."
  echo "Fix: Start Docker Desktop, wait until it says 'Running', then rerun."
  exit 1
fi

# Optional teardown
if [[ "${1:-}" == "--down" ]]; then
  tmux has-session -t "$session" 2>/dev/null && tmux kill-session -t "$session" || true
  docker compose down --remove-orphans || true

  # Remove fixed-name containers if they exist (safe for demo environment)
  for c in zookeeper broker1 broker2 broker3 prometheus grafana \
           jmx-exporter-broker1 jmx-exporter-broker2 jmx-exporter-broker3 kafka-exporter; do
    docker rm -f "$c" >/dev/null 2>&1 || true
  done
  exit 0
fi

echo "Cleaning old containers (demo-safe hard reset)"
for c in zookeeper broker1 broker2 broker3 prometheus grafana \
         jmx-exporter-broker1 jmx-exporter-broker2 jmx-exporter-broker3 kafka-exporter; do
  docker rm -f "$c" >/dev/null 2>&1 || true
done

docker compose down --remove-orphans --timeout 5 >/dev/null 2>&1 || true

echo "Starting containers..."
docker compose up -d --force-recreate --remove-orphans

echo ""
docker compose ps
echo ""

echo "Waiting for broker1 Kafka listener on 9092..."

ready=0
for i in {1..60}; do
  # broker process exists?
  if docker exec broker1 bash -lc "ps aux | grep -E '[k]afka.Kafka' >/dev/null"; then
    # port open? (no timeout dependency)
    if docker exec broker1 bash -lc "bash -lc '</dev/tcp/localhost/9092' >/dev/null 2>&1"; then
      echo "Kafka is listening on broker1:9092"
      ready=1
      break
    fi
  fi
  sleep 1
done

if [[ "$ready" -ne 1 ]]; then
  echo ""
  echo "ERROR: Kafka did not become ready on broker1:9092."
  docker compose ps -a || true
  docker compose logs broker1 --tail=200 || true
  exit 1
fi

# Final validation: CLI must work
if ! docker exec broker1 bash -lc "unset JMX_PORT KAFKA_JMX_OPTS KAFKA_JMX_PORT; kafka-topics --bootstrap-server broker1:9092 --list >/dev/null 2>&1"; then
  echo ""
  echo "ERROR: Kafka CLI not ready. Printing broker logs."
  docker compose ps -a || true
  docker compose logs broker1 --tail=200 || true
  exit 1
fi

# Fresh tmux
tmux has-session -t "$session" 2>/dev/null && tmux kill-session -t "$session" || true

t1_title="#[bg=colour27,fg=white,bold]   Broker Metrics (JMX)   #[default]"
t2_title="#[bg=colour34,fg=black,bold]   Consumer Lag (CLI)   #[default]"
t3_title="#[bg=colour214,fg=black,bold]   Producer Load   #[default]"

run_clean() {
  echo "cd '$start_dir'; clear; bash"
}

tmux new-session -d -s "$session" -n "kafka" "$(run_clean)"
tmux split-window -v -t "$session":0.0 "$(run_clean)"
tmux split-window -v -t "$session":0.1 "$(run_clean)"

tmux select-pane -t "$session":0.0 -T "$t1_title"
tmux select-pane -t "$session":0.1 -T "$t2_title"
tmux select-pane -t "$session":0.2 -T "$t3_title"

# Runbook: matches your required sequence exactly
tmux send-keys -t "$session":0.0 \
"clear; printf '\nSTEP 1 (T1): ./scripts/01-create-topic.sh\nSTEP 6 (T1): ./scripts/05-jmx-broker-stats.sh\nSTEP 7 (T1): ./scripts/06-jmx-throughput.sh\nSTEP 8 (T1): ./scripts/07-jmx-request-latency.sh\n\n'" C-m

tmux send-keys -t "$session":0.1 \
"clear; printf '\nSTEP 3 (T2): ./scripts/04-check-lag.sh   (expect: group not found)\nSTEP 4 (T2): ./scripts/03-start-consumer.sh &\nSTEP 5 (T2): ./scripts/04-check-lag.sh; sleep 2; ./scripts/04-check-lag.sh\n\n'" C-m

tmux send-keys -t "$session":0.2 \
"clear; printf '\nSTEP 2 (T3): ./scripts/02-start-load.sh   (leave running)\n\n'" C-m

tmux select-pane -t "$session":0.1
tmux attach-session -t "$session"
