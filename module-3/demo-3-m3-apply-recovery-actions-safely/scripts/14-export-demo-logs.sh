#!/usr/bin/env bash
set -euo pipefail

# Exports:
# - T1 console scrollback from tmux (auto-picks the "largest" pane, usually T1 top pane)
# - broker2 docker logs
# - broker1 docker logs
# - consumer log + producer warn log from inside broker1 container (if present)
# Writes everything to: ~/Desktop/demo-logs-<timestamp>/

OUT_DIR="${OUT_DIR:-$HOME/Desktop}"
STAMP="$(date +%Y%m%d-%H%M%S)"
DEST="$OUT_DIR/demo-logs-$STAMP"

mkdir -p "$DEST"

echo "[1/5] Exporting tmux pane scrollback (T1)…"
if [[ -n "${TMUX:-}" ]]; then
  # Pick the pane with the largest height (your layout: T1 is the big top pane)
  PANE_ID="$(tmux list-panes -F '#{pane_id} #{pane_height} #{pane_width}' \
    | sort -nr -k2 \
    | head -n1 \
    | awk '{print $1}')"

  echo "  Using pane: $PANE_ID"
  # Capture a lot of history (increase -S value if you want even more)
  tmux capture-pane -p -t "$PANE_ID" -S -50000 > "$DEST/01-t1-console-scrollback.txt"
else
  echo "  ERROR: Not running inside tmux. Run this script from inside your tmux session."
  exit 1
fi

echo "[2/5] Exporting broker2 docker logs…"
docker logs broker2 --tail 200000 > "$DEST/02-broker2-docker.log.txt" 2>&1 || true

echo "[3/5] Exporting broker1 docker logs…"
docker logs broker1 --tail 200000 > "$DEST/03-broker1-docker.log.txt" 2>&1 || true

echo "[4/5] Exporting consumer/prod logs from inside broker1 container…"
docker exec broker1 bash -lc "test -f /tmp/ops-demo-consumer.log && tail -n 200000 /tmp/ops-demo-consumer.log" \
  > "$DEST/04-consumer.log.txt" 2>&1 || true

docker exec broker1 bash -lc "test -f /tmp/ops-demo-producer.warn && tail -n 200000 /tmp/ops-demo-producer.warn" \
  > "$DEST/05-producer.warn.txt" 2>&1 || true

echo "[5/5] Creating a quick snapshot of tmux layout + env…"
{
  echo "=== DATE ==="
  date
  echo
  echo "=== TMUX LIST-PANES ==="
  tmux list-panes -a -F '#{session_name}:#{window_index}.#{pane_index}  #{pane_id}  #{pane_height}x#{pane_width}  "#{pane_title}"  "#{pane_current_command}"'
  echo
  echo "=== ENV (filtered) ==="
  env | egrep 'TOPIC=|GROUP|GROUP_ID|BOOTSTRAP|BROKER|REFRESH|WINDOW|THROUGHPUT|STOP_FILE' || true
} > "$DEST/06-snapshot.txt"

echo
echo "✅ Done."
echo "📁 Folder: $DEST"
echo "Next: zip it and upload here:"
echo "   cd \"$OUT_DIR\" && zip -r \"demo-logs-$STAMP.zip\" \"demo-logs-$STAMP\""
