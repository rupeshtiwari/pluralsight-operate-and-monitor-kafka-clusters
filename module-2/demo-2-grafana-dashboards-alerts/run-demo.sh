#!/usr/bin/env bash
set -euo pipefail

export COMPOSE_PROJECT_NAME=ps-kafka-m2-demo2
export COMPOSE_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/docker-compose.yml"

# Avoid accidental overrides (common cause of weird DNS / "no such host")
unset DOCKER_HOST DOCKER_CONTEXT COMPOSE_PROFILES

session="kafka-demo"

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$script_dir"

need() { command -v "$1" >/dev/null 2>&1 || { echo "Missing dependency: $1"; exit 1; }; }
need docker
need tmux

if [[ "${1:-}" == "--down" ]]; then
  tmux kill-session -t "$session" 2>/dev/null || true
  docker compose down -v --remove-orphans || true
  exit 0
fi

echo "Starting containers (Kafka + Exporters + Prometheus + Grafana)"
docker compose up -d --force-recreate --remove-orphans

echo "Waiting for broker1 Kafka listener on 9092..."
for i in {1..90}; do
  if docker exec broker1 bash -lc "ps aux | grep -E '[k]afka.Kafka' >/dev/null"; then
    if docker exec broker1 bash -lc "bash -lc '</dev/tcp/localhost/9092' >/dev/null 2>&1"; then
      echo "Kafka is listening on broker1:9092"
      break
    fi
  fi
  sleep 1
done

# Final validation: topic list must work
if ! docker exec broker1 bash -lc "unset JMX_PORT KAFKA_JMX_OPTS KAFKA_JMX_PORT; kafka-topics --bootstrap-server broker1:9092 --list >/dev/null 2>&1"; then
  echo ""
  echo "ERROR: Kafka is not ready on broker1:9092. Printing broker logs."
  docker compose ps -a || true
  docker compose logs broker1 --tail=200 || true
  exit 1
fi

echo ""
echo "URLs:"
echo "  Prometheus Targets: http://localhost:9090/targets"
echo "  Grafana:           http://localhost:3000   (admin/admin)"
echo ""

# fresh tmux
tmux has-session -t "$session" 2>/dev/null && tmux kill-session -t "$session" || true

t1_title="#[bg=colour27,fg=white,bold]   T1 - Broker Metrics (JMX)   #[default]"
t2_title="#[bg=colour34,fg=black,bold]   T2 - Consumer Lag (CLI)     #[default]"
t3_title="#[bg=colour214,fg=black,bold]  T3 - Producer Load          #[default]"

run_clean() {
  echo "cd '$script_dir'; clear; bash -c 'PS1=\"\$ \"; while true; do read -r -p \"\$ \" cmd; eval \"\$cmd\"; done'"
}

tmux new-session -d -s "$session" -n "kafka" "$(run_clean)"
tmux split-window -v -t "$session":0.0 "$(run_clean)"
tmux split-window -v -t "$session":0.1 "$(run_clean)"

tmux select-pane -t "$session":0.0 -T "$t1_title"
tmux select-pane -t "$session":0.1 -T "$t2_title"
tmux select-pane -t "$session":0.2 -T "$t3_title"

tmux send-keys -t "$session":0.0 \
"clear; printf '\nSTEP 1 (T1): ./scripts/01-create-topic.sh\nSTEP 6 (T1): ./scripts/05-jmx-broker-stats.sh\nSTEP 7 (T1): ./scripts/06-jmx-throughput.sh\nSTEP 8 (T1): ./scripts/07-jmx-request-latency.sh\n\n'" C-m

tmux send-keys -t "$session":0.1 \
"clear; printf '\nSTEP 3 (T2): ./scripts/04-check-lag.sh  (expect: group not found)\nSTEP 4 (T2): ./scripts/03-start-consumer.sh &\nSTEP 5 (T2): ./scripts/04-check-lag.sh; sleep 2; ./scripts/04-check-lag.sh\n\n'" C-m

tmux send-keys -t "$session":0.2 \
"clear; printf '\nSTEP 2 (T3): ./scripts/02-start-load.sh  (leave running)\n\nPrometheus: http://localhost:9090/targets\nGrafana:    http://localhost:3000  (admin/admin)\n\n'" C-m

tmux select-pane -t "$session":0.1
tmux attach-session -t "$session"
