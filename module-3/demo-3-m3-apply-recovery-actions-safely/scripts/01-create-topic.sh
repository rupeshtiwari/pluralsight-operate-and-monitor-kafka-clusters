#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/00-env.sh"

BROKERS=(broker1 broker2 broker3)

RED=$'\033[31m'; YELLOW=$'\033[33m'; GREEN=$'\033[32m'; CYAN=$'\033[36m'; BOLD=$'\033[1m'; RESET=$'\033[0m'
hr(){ printf '%s\n' "--------------------------------------------------------------------------------"; }
die(){ echo -e "${RED}[ERR]${RESET} $*" >&2; exit 1; }

echo -e "${CYAN}${BOLD}🔧 Create Topic${RESET}"
hr
printf "📌 Topic:      %s\n" "$TOPIC"
printf "🛰️ Bootstrap:  %s\n" "$BOOTSTRAP_SERVERS"
printf "🧩 Partitions: %s\n" "$PARTITIONS"
printf "🧱 RF:         %s\n" "$REPLICATION_FACTOR"
hr

echo "⏳ Waiting for broker containers to be running..."
for i in $(seq 1 60); do
  ok=1
  for b in "${BROKERS[@]}"; do
    st="$(docker inspect -f '{{.State.Status}}' "$b" 2>/dev/null || echo missing)"
    if [[ "$st" != "running" ]]; then
      ok=0
      printf "[%d/60] %s status=%s (waiting to be running...)\n" "$i" "$b" "$st"
      break
    fi
  done
  [[ "$ok" -eq 1 ]] && break
  sleep 1
  [[ "$i" -eq 60 ]] && die "Brokers are not all running. Check: docker ps && docker logs broker1"
done

echo "⏳ Waiting for Kafka to answer metadata on $BOOTSTRAP_SERVERS ..."
for i in $(seq 1 60); do
  if docker exec "$BROKER_CONTAINER" bash -lc "kafka-broker-api-versions --bootstrap-server '$BOOTSTRAP_SERVERS' >/dev/null 2>&1"; then
    echo "✅ Kafka is reachable."
    break
  fi
  printf "[%d/60] Kafka not ready yet...\n" "$i"
  sleep 1
  [[ "$i" -eq 60 ]] && die "Kafka never became reachable on $BOOTSTRAP_SERVERS"
done

broker_count="$(
  docker exec "$BROKER_CONTAINER" bash -lc \
    "kafka-broker-api-versions --bootstrap-server '$BOOTSTRAP_SERVERS' 2>/dev/null | grep -Eo '\\(id: [0-9]+' | wc -l | tr -d '[:space:]' || true"
)"
broker_count="${broker_count:-0}"

rf="$REPLICATION_FACTOR"
if [[ "$broker_count" =~ ^[0-9]+$ ]] && (( broker_count > 0 )) && (( rf > broker_count )); then
  echo -e "${YELLOW}⚠️  Only ${broker_count} broker(s) visible. Falling back to RF=${broker_count}${RESET}"
  rf="$broker_count"
fi

if docker exec "$BROKER_CONTAINER" bash -lc "kafka-topics --bootstrap-server '$BOOTSTRAP_SERVERS' --topic '$TOPIC' --describe >/dev/null 2>&1"; then
  echo -e "${GREEN}✅ Topic '${TOPIC}' already exists.${RESET}"
  exit 0
fi

echo "🛠️  Creating topic '${TOPIC}' with ${PARTITIONS} partitions and RF=${rf}..."
docker exec "$BROKER_CONTAINER" bash -lc "
  set -euo pipefail
  kafka-topics --bootstrap-server '$BOOTSTRAP_SERVERS' \
    --create --if-not-exists \
    --topic '$TOPIC' \
    --partitions '$PARTITIONS' \
    --replication-factor '$rf'
" >/dev/null

echo -e "${GREEN}✅ Topic '${TOPIC}' created (or already exists).${RESET}"
