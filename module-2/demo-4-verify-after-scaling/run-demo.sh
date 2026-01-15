#!/usr/bin/env bash
set -euo pipefail

export COMPOSE_PROJECT_NAME=ps-kafka-m2-demo4
export COMPOSE_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/docker-compose.yml"
unset DOCKER_HOST DOCKER_CONTEXT COMPOSE_PROFILES

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$script_dir"

TOPIC="${TOPIC:-ops-demo-reassign-v1}"
GROUP="${GROUP:-ops-demo-monitor-group}"
BROKER="${BROKER:-broker1:9092}"

# shellcheck source=/dev/null
source "$script_dir/scripts/99-ui.sh"

need() { command -v "$1" >/dev/null 2>&1 || { echo "Missing dependency: $1"; exit 1; }; }
need docker

clear || true
ui_h1 "DEMO 4 STARTUP"
hr
printf "%b\n" "${DIM}Deterministic startup: brokers up, topic ready, consumer group started, offsets seeded${RESET}"
hr
echo

ui_tag "STEP 1"
printf "%b\n" "${BOLD}Start containers${RESET}"

# Clean up stale network from older runs (safe)
if docker network inspect ps-kafka-m2-demo4-net >/dev/null 2>&1; then
  ui_tag "CLEANUP"
  echo "Removing stale network: ps-kafka-m2-demo4-net"
  docker network rm ps-kafka-m2-demo4-net >/dev/null 2>&1 || true
fi

docker compose up -d --remove-orphans >/dev/null 2>&1
ui_ok "Containers launched"
echo

ui_tag "STEP 2"
printf "%b\n" "${BOLD}Wait for ZooKeeper + brokers healthy${RESET}"

# Wait for ZooKeeper health
for i in {1..60}; do
  zk="$(docker inspect -f '{{.State.Health.Status}}' zookeeper 2>/dev/null || echo starting)"
  if [[ "$zk" == "healthy" ]]; then
    ui_ok "ZooKeeper is healthy"
    break
  fi
  if (( i == 60 )); then
    ui_err "ZooKeeper did not become healthy"
    docker logs zookeeper --tail 120 || true
    exit 1
  fi
  sleep 1
done

# Wait for brokers health
for i in {1..120}; do
  b1="$(docker inspect -f '{{.State.Health.Status}}' broker1 2>/dev/null || echo starting)"
  b2="$(docker inspect -f '{{.State.Health.Status}}' broker2 2>/dev/null || echo starting)"
  b3="$(docker inspect -f '{{.State.Health.Status}}' broker3 2>/dev/null || echo starting)"

  if [[ "$b1" == "healthy" && "$b2" == "healthy" && "$b3" == "healthy" ]]; then
    ui_ok "All brokers are healthy"
    break
  fi

  if (( i == 120 )); then
    ui_err "One or more brokers did not become healthy"
    echo "broker1=$b1 broker2=$b2 broker3=$b3"
    docker logs broker1 --tail 120 || true
    docker logs broker2 --tail 120 || true
    docker logs broker3 --tail 120 || true
    exit 1
  fi
  sleep 1
done
echo

export TOPIC GROUP BROKER

ui_tag "STEP 3"
printf "%b\n" "${BOLD}Prepare topic + consumer group${RESET}"
./scripts/01-prepare-state.sh >/dev/null 2>&1
./scripts/02-start-consumer-bg.sh >/dev/null 2>&1
ui_ok "Topic and consumer group created"
echo

ui_tag "STEP 4"
printf "%b\n" "${BOLD}Seed offsets until lag is visible${RESET}"

# Keep seeding until offsets show up (max ~20s)
for i in {1..20}; do
  docker exec broker1 bash -lc "printf 'seed-%s\n' $i | kafka-console-producer --bootstrap-server '$BROKER' --topic '$TOPIC' >/dev/null 2>&1" || true
  sleep 1

  # FIX: output columns are GROUP TOPIC PARTITION CURRENT LOG_END LAG ...
  if docker exec broker1 bash -lc "kafka-consumer-groups --bootstrap-server '$BROKER' --group '$GROUP' --describe 2>/dev/null \
      | awk -v g='$GROUP' -v t='$TOPIC' '\$1==g && \$2==t {found=1} END{exit !found}'"; then
    ui_ok "Offsets visible (lag table will show rows)"
    break
  fi

  if (( i == 20 )); then
    ui_err "Offsets still not visible. Consumer is not committing (or consumer failed)."
    echo "Check: docker exec broker1 bash -lc \"tail -n 50 /tmp/demo4_consumer.log\""
    exit 1
  fi
done
echo

ui_h1 "ENV CHECKLIST"
hr
printf "%b\n" "${GREEN}•${RESET} ${BOLD}ZooKeeper${RESET} healthy"
printf "%b\n" "${GREEN}•${RESET} ${BOLD}Brokers${RESET} healthy (3)"
printf "%b\n" "${GREEN}•${RESET} ${BOLD}Topic${RESET}: ${CYAN}$TOPIC${RESET}"
printf "%b\n" "${GREEN}•${RESET} ${BOLD}Group${RESET}: ${CYAN}$GROUP${RESET}"
printf "%b\n" "${GREEN}•${RESET} Offsets seeded so lag is visible"
hr
echo

ui_h1 "START THE DEMO"
hr
printf "%b\n" "${BOLD}Terminal B${RESET}  ${DIM}(observation)${RESET}"
printf "%b\n" "  ${BOLD}./watch-lag.sh${RESET}"
echo
printf "%b\n" "${BOLD}Terminal A${RESET}  ${DIM}(action)${RESET}"
printf "%b\n" "  ${BOLD}./start-load.sh${RESET}"
printf "%b\n" "  ${BOLD}./show-leaders.sh${RESET}"
hr
echo
