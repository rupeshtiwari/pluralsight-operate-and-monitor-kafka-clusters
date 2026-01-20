#!/usr/bin/env bash
set -euo pipefail

# Module 3 Demo 2: Correlate Logs with Metrics
# Focus: timestamps + metrics impact + broker log cause

export COMPOSE_PROJECT_NAME=ps-kafka-m3-demo2
export COMPOSE_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/docker-compose.yml"

# Avoid accidental overrides (common cause of weird DNS / "no such host")
unset DOCKER_HOST DOCKER_CONTEXT COMPOSE_PROFILES

session="demo-2-m3"

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
echo "Grafana path for the demo:"
echo "  Dashboards -> Kafka Operational Health"
echo "  Time range: Last 15 minutes"
echo "  Refresh: 5s"
echo ""

# fresh tmux session
tmux has-session -t "$session" 2>/dev/null && tmux kill-session -t "$session" || true

t1_title="#[bg=colour27,fg=white,bold]   T1 - Control + Lag Snapshot   #[default]"
t2_title="#[bg=colour160,fg=white,bold]  T2 - Broker2 Logs (Filtered)  #[default]"
t3_title="#[bg=colour214,fg=black,bold]  T3 - Producer Load            #[default]"

run_clean() {
  echo "cd '$script_dir'; clear; bash -c 'PS1=\"\$ \"; while true; do read -r -p \"\$ \" cmd; eval \"\$cmd\"; done'"
}

# Create 3 panes
tmux new-session -d -s "$session" -n "demo" "$(run_clean)"
tmux split-window -v -t "$session":0.0 "$(run_clean)"
tmux split-window -v -t "$session":0.1 "$(run_clean)"

tmux select-pane -t "$session":0.0 -T "$t1_title"
tmux select-pane -t "$session":0.1 -T "$t2_title"
tmux select-pane -t "$session":0.2 -T "$t3_title"

# T1 instructions (control + lag)
tmux send-keys -t "$session":0.0 \
"clear; printf '\nMODULE 3 DEMO 2: Correlate Logs with Metrics\n\nRun order (T1):\n  STEP 1: ./scripts/01-create-topic.sh\n  STEP 2: ./scripts/04-check-lag.sh    (expect: group not found)\n  STEP 3: ./scripts/03-start-consumer.sh &\n  STEP 4: ./scripts/04-check-lag.sh    (baseline lag snapshot)\n  STEP 7: ./scripts/09-restart-broker2.sh  (incident trigger)\n  STEP 8: ./scripts/04-check-lag.sh; sleep 2; ./scripts/04-check-lag.sh\n\nPrimary teaching happens in Grafana (timestamps).\n\n'" C-m

# T2 instructions (logs) - provide the exact command to run
tmux send-keys -t "$session":0.1 \
"clear; printf '\nBroker2 logs should be high-signal only.\n\nRun (T2) BEFORE you restart broker2:\n  docker logs -f broker2 2>&1 | egrep -i \"ERROR|WARN|shutdown|starting|LeaderAndIsr|become-leader|become-follower|isr|under|replica|fetch|controller|m3-correlation\"\n\nTip: when the Grafana latency spikes, read 1-2 log lines with the same timestamp.\n\n'" C-m

# T3 instructions (load)
tmux send-keys -t "$session":0.2 \
"clear; printf '\nStart producer load and leave it running:\n\n  STEP 5 (T3): ./scripts/02-start-load.sh\n\nExpected:\n  ~19k-20k records/sec\n  ~9-10 MB/sec\n  avg latency single-digit ms\n\nAfter load starts, switch to Grafana and establish baseline.\n\n'" C-m

tmux select-pane -t "$session":0.0
tmux attach-session -t "$session"
