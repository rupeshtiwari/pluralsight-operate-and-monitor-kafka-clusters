#!/usr/bin/env bash
set -euo pipefail

RED=$'\033[31m'; GREEN=$'\033[32m'; CYAN=$'\033[36m'; BOLD=$'\033[1m'; RESET=$'\033[0m'; DIM=$'\033[2m'
hr(){ printf '%s\n' "--------------------------------------------------------------------------------"; }
die(){ echo -e "${RED}[ERR]${RESET} $*" >&2; exit 1; }

echo -e "${CYAN}${BOLD}🔁 Restarting broker2 safely${RESET}"
hr

docker inspect broker2 >/dev/null 2>&1 || die "Container 'broker2' not found."
docker restart broker2 >/dev/null

echo -e "${DIM}⏳ Waiting for broker2 container to be running and Kafka to respond...${RESET}"
for i in $(seq 1 60); do
  st="$(docker inspect -f '{{.State.Status}}' broker2 2>/dev/null || echo missing)"
  if [[ "$st" != "running" ]]; then
    printf "[%d/60] broker2 status=%s\n" "$i" "$st"
    sleep 1
    continue
  fi

  if docker exec broker2 bash -lc "kafka-broker-api-versions --bootstrap-server broker2:9092 >/dev/null 2>&1"; then
    echo -e "${GREEN}✅ broker2 is reachable.${RESET}"
    exit 0
  fi

  printf "[%d/60] running but Kafka not ready yet...\n" "$i"
  sleep 1
done

die "broker2 did not become reachable. Check: docker logs --tail=120 broker2"
