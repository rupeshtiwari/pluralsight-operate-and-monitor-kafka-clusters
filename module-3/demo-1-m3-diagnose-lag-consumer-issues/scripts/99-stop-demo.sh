#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/99-ui.sh"

title "Stop Demo Environment"

docker compose down -v
ok "Stopped and removed containers + volumes"
