#!/usr/bin/env bash
set -euo pipefail

# =========================
# Export logs for narration
# =========================

# Where to save (Desktop by default)
DESKTOP_DIR="${HOME}/Desktop"
OUT_DIR="${DESKTOP_DIR}/demo-logs-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$OUT_DIR"

# Which broker container is the "incident" broker
BROKER2_CONTAINER="${BROKER2_CONTAINER:-broker2}"

echo "Saving demo logs to: $OUT_DIR"
echo

# 1) broker2 docker logs (this is the most important)
echo "[1/4] Exporting docker logs from ${BROKER2_CONTAINER} ..."
docker logs "$BROKER2_CONTAINER" > "$OUT_DIR/01-broker2-docker.log.txt" 2>&1 || true
echo "  -> $OUT_DIR/01-broker2-docker.log.txt"

# 2) broker1 docker logs (optional but useful for context)
echo "[2/4] Exporting docker logs from broker1 (context) ..."
docker logs broker1 > "$OUT_DIR/02-broker1-docker.log.txt" 2>&1 || true
echo "  -> $OUT_DIR/02-broker1-docker.log.txt"

# 3) T1 tmux pane scrollback (what you saw on screen)
#    This captures the last 10k lines from the active pane you run it in.
echo "[3/4] Capturing tmux pane scrollback (run this script IN the T1 pane) ..."
if [[ -n "${TMUX:-}" ]]; then
  tmux capture-pane -S -10000 -p > "$OUT_DIR/03-t1-pane-last10000.log.txt" 2>/dev/null || true
  echo "  -> $OUT_DIR/03-t1-pane-last10000.log.txt"
else
  echo "  (Not in tmux. Skipping pane capture.)"
fi

# 4) Save a quick system snapshot (helps narration)
echo "[4/4] Writing a quick snapshot (containers, time, config) ..."
{
  echo "Timestamp: $(date -Is)"
  echo
  echo "docker ps:"
  docker ps || true
  echo
  echo "Environment guesses:"
  echo "BROKER2_CONTAINER=${BROKER2_CONTAINER}"
} > "$OUT_DIR/04-snapshot.txt" 2>&1
echo "  -> $OUT_DIR/04-snapshot.txt"

# Zip everything into one file for easy upload
ZIP_FILE="${OUT_DIR}.zip"
echo
echo "Creating zip: $ZIP_FILE"
(cd "$(dirname "$OUT_DIR")" && zip -r "$(basename "$ZIP_FILE")" "$(basename "$OUT_DIR")" >/dev/null)

echo
echo "✅ Done."
echo "Upload this file to me:"
echo "   $ZIP_FILE"
