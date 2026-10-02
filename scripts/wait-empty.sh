#!/usr/bin/env bash
# Poll Minecraft status ping until online player count is 0. Does not kick anyone.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HOST="${1:-127.0.0.1}"
PORT="${2:-25565}"
INTERVAL="${EMPTY_POLL_SECONDS:-30}"

echo "[empty] waiting for 0 players on ${HOST}:${PORT} (poll ${INTERVAL}s, no timeout)"
while true; do
  if ! out="$(python3 "$ROOT/scripts/mc-status.py" "$HOST" "$PORT" 2>/dev/null)"; then
    echo "[empty] status unreachable — treating as 0 players"
    exit 0
  fi
  echo "[empty] online=$out"
  if [[ "$out" == "0" ]]; then
    echo "[empty] server is empty"
    exit 0
  fi
  sleep "$INTERVAL"
done
