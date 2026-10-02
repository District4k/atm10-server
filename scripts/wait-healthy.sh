#!/usr/bin/env bash
# Wait until a Minecraft port answers server-list ping.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HOST="${1:-127.0.0.1}"
PORT="${2:-25565}"
TIMEOUT="${3:-900}"
INTERVAL=10
deadline=$((SECONDS + TIMEOUT))

echo "[health] waiting for ping ${HOST}:${PORT} (up to ${TIMEOUT}s)"
while (( SECONDS < deadline )); do
  if python3 "$ROOT/scripts/mc-status.py" "$HOST" "$PORT" >/dev/null 2>&1; then
    echo "[health] ${HOST}:${PORT} is up"
    exit 0
  fi
  sleep "$INTERVAL"
done
echo "[health] ${HOST}:${PORT} did not become ready" >&2
exit 1
