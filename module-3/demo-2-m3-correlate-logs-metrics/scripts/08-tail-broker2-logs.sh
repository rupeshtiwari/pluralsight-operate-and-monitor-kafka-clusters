#!/usr/bin/env bash
set -euo pipefail

# Backward-compatible name.
# Use this during the demo to watch only high-signal broker2 events.

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$DIR/06-watch-broker2-events.sh"
