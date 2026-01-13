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

if [[ "${1:-}" == "--down" ]]; then
  docker compose down --remove-orphans || true
  for c in zookeeper broker1 broker2 broker3; do
    docker stop "$c" >/dev/null 2>&1 || true
    docker rm "$c" >/dev/null 2>&1 || true
  done
  exit 0
fi

echo "Cleaning old containers (safe across modules)"
for c in zookeeper broker1 broker2 broker3; do
  docker rm -f "$c" >/dev/null 2>&1 || true
done

# also tear down compose project artifacts quickly
docker compose down --remove-orphans --timeout 5 >/dev/null 2>&1 || true


echo "Starting containers"
docker compose up -d --force-recreate --remove-orphans


echo "Waiting for broker1 Kafka listener on 9092..."

# wait for the kafka process to exist and port 9092 to accept
for i in {1..60}; do
  # check broker process
  if docker exec broker1 bash -lc "ps aux | grep -E '[k]afka.Kafka' >/dev/null"; then
    # check port open inside container (bash /dev/tcp trick)
    if docker exec broker1 bash -lc "timeout 1 bash -lc '</dev/tcp/localhost/9092' >/dev/null 2>&1"; then
      echo "Kafka is listening on broker1:9092"
      break
    fi
  fi
  sleep 1
done

# final validation: topic list must work
if ! docker exec broker1 bash -lc "unset JMX_PORT KAFKA_JMX_OPTS KAFKA_JMX_PORT; kafka-topics --bootstrap-server broker1:9092 --list >/dev/null 2>&1"; then
  echo ""
  echo "ERROR: Kafka is not ready on broker1:9092. Printing broker logs."
  docker compose ps -a || true
  docker compose logs broker1 --tail=200 || true
  exit 1
fi


# fresh tmux
tmux has-session -t "$session" 2>/dev/null && tmux kill-session -t "$session" || true

t1_title="#[bg=colour27,fg=white,bold]   Broker Metrics (JMX)   #[default]"
t2_title="#[bg=colour34,fg=black,bold]   Consumer Lag (CLI)   #[default]"
t3_title="#[bg=colour214,fg=black,bold]   Producer Load   #[default]"

run_clean() {
  echo "cd '$start_dir'; clear; bash -c 'PS1=\"\$ \"; while true; do read -r -p \"\$ \" cmd; eval \"\$cmd\"; done'"
}




tmux new-session -d -s "$session" -n "kafka" "$(run_clean)"
tmux split-window -v -t "$session":0.0 "$(run_clean)"
tmux split-window -v -t "$session":0.1 "$(run_clean)"

tmux select-pane -t "$session":0.0 -T "$t1_title"
tmux select-pane -t "$session":0.1 -T "$t2_title"
tmux select-pane -t "$session":0.2 -T "$t3_title"

# Print runbook (do not run automatically)
# Print runbook once per pane (clean, no repetition)
tmux send-keys -t "$session":0.0 \
"clear; printf '\nNext: ./scripts/01-create-topic.sh\nThen: 05-jmx-broker-stats.sh\n      06-jmx-throughput.sh\n      07-jmx-request-latency.sh\n\n'" C-m

tmux send-keys -t "$session":0.1 \
"clear; printf '\nNext: ./scripts/03-start-consumer.sh\nThen: ./scripts/04-check-lag.sh (run twice)\n\n'" C-m

tmux send-keys -t "$session":0.2 \
"clear; printf '\nNext: ./scripts/02-start-load.sh (leave running)\n\n'" C-m



tmux select-pane -t "$session":0.1
tmux attach-session -t "$session"
