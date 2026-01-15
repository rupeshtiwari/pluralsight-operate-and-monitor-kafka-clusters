#!/usr/bin/env bash
set -euo pipefail

TOPIC="ops-demo-reassign-v1"
BOOTSTRAP="broker1:9092"
BROKER_CONTAINER="broker1"

# Avoid JMX env collisions inside containers
KAFKA_ENV_FIX='unset JMX_PORT KAFKA_JMX_PORT KAFKA_JMX_OPTS;'

# ANSI colors
BOLD="\033[1m"
DIM="\033[2m"
RESET="\033[0m"
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
MAGENTA="\033[35m"
CYAN="\033[36m"
GRAY="\033[90m"

need() { command -v "$1" >/dev/null 2>&1 || { echo -e "${RED}Missing dependency:${RESET} $1"; exit 1; }; }

# Required for formatted output (host tools)
need jq
need pr
need awk
need sed
need column

hr() { printf "%b\n" "${GRAY}--------------------------------------------------------------------------------${RESET}"; }
h1() { printf "%b\n" "${BOLD}${CYAN}$1${RESET}"; }
ok() { printf "%b\n" "${GREEN}${BOLD}OK:${RESET} $1"; }
warn() { printf "%b\n" "${YELLOW}${BOLD}NOTE:${RESET} $1"; }
fail() { printf "%b\n" "${RED}${BOLD}ERROR:${RESET} $1"; exit 1; }
