#!/usr/bin/env bash
set -euo pipefail

export COMPOSE_PROJECT_NAME=ps-kafka-m2-demo4
export COMPOSE_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/docker-compose.yml"

unset DOCKER_HOST DOCKER_CONTEXT COMPOSE_PROFILES

session="kafka-demo4"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$script_dir"

need() { command -v "$1" >/dev/null 2>&1 || { echo "Missing dependency: $1"; exit 1; }; }
need docker
need tmux
need watch

echo "Starting containers (ZooKeeper + 3 brokers only)"
docker compose up -d --force-recreate --remove-orphans

echo "Waiting for Kafka on broker1:9092..."
for i in {1..90}; do
  if docker exec broker1 bash -lc "ps aux | grep -E '[k]afka.Kafka' >/dev/null"; then
    if docker exec broker1 bash -lc "bash -lc '</dev/tcp/localhost/9092' >/dev/null 2>&1"; then
      echo "Kafka is listening on broker1:9092"
      break
    fi
  fi
  sleep 1
done

if ! docker exec broker1 bash -lc "unset JMX_PORT KAFKA_JMX_OPTS KAFKA_JMX_PORT; kafka-topics --bootstrap-server broker1:9092 --list >/dev/null 2>&1"; then
  echo ""
  echo "ERROR: Kafka is not ready on broker1:9092. Printing broker logs."
  docker compose ps -a || true
  docker compose logs broker1 --tail=200 || true
  exit 1
fi

echo ""
echo "Demo 4 commands are in: ./scripts/"
echo ""

tmux has-session -t "$session" 2>/dev/null && tmux kill-session -t "$session" || true

run_clean() {
  echo "cd '$script_dir'; clear; bash -c 'PS1=\"$ \"; while true; do read -r -p \"$ \" cmd; eval \"$cmd\"; done'"
}

# 2x2 panes
# T1: Lag watch
# T2: Leader count watch
# T3: ISR watch
# T4: Producer load / helper commands

tmux new-session -d -s "$session" -n "kafka" "$(run_clean)"
tmux split-window -h -t "$session":0.0 "$(run_clean)"
tmux split-window -v -t "$session":0.0 "$(run_clean)"
tmux split-window -v -t "$session":0.2 "$(run_clean)"

# Pane titles
tmux select-pane -t "$session":0.0 -T "#[bg=colour27,fg=white,bold] T1 - Lag #[default]"
tmux select-pane -t "$session":0.1 -T "#[bg=colour34,fg=black,bold] T2 - Leaders #[default]"
tmux select-pane -t "$session":0.2 -T "#[bg=colour220,fg=black,bold] T3 - ISR #[default]"
tmux select-pane -t "$session":0.3 -T "#[bg=colour213,fg=white,bold] T4 - Load / Setup #[default]"

# Suggested commands
tmux send-keys -t "$session":0.3 "clear; printf '\nSTEP 0 (optional standalone): ./scripts/01-ensure-topic-ready.sh\n\nSTEP 1: ./scripts/02-start-consumer.sh (leave running)\nSTEP 2: ./scripts/03-watch-lag.sh\nSTEP 3: ./scripts/04-watch-leader-count.sh\nSTEP 4: ./scripts/06-watch-isr.sh\nSTEP 5: ./scripts/05-run-load.sh\n\nOptional: ./scripts/07-run-preferred-leader-election.sh\n\n'" C-m

# Start the watch panes ready (user can hit enter)
tmux send-keys -t "$session":0.0 "clear; echo 'Run: ./scripts/03-watch-lag.sh'" C-m
tmux send-keys -t "$session":0.1 "clear; echo 'Run: ./scripts/04-watch-leader-count.sh'" C-m
tmux send-keys -t "$session":0.2 "clear; echo 'Run: ./scripts/06-watch-isr.sh'" C-m

# Focus on T4
tmux select-pane -t "$session":0.3
tmux attach-session -t "$session"
