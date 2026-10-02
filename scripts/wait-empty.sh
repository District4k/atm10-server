#!/usr/bin/env bash
# Poll until 0 players. While people are online, periodically announce the pending update.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
for f in "$ROOT/deploy.env" "$ROOT/.env"; do
  if [[ -f "$f" ]]; then
    set -a
    # shellcheck disable=SC1090
    source "$f"
    set +a
  fi
done

HOST="${1:-${STATUS_HOST:-127.0.0.1}}"
PORT="${2:-${MC_PORT:-25565}}"
VERSION="${3:-${UPDATE_VERSION:-$(tr -d '[:space:]' < "$ROOT/VERSION")}}"
INTERVAL="${EMPTY_POLL_SECONDS:-30}"
ANNOUNCE_EVERY="${UPDATE_ANNOUNCE_EVERY:-2}"  # every N polls (~60s if interval=30)

echo "[empty] waiting for 0 players on ${HOST}:${PORT} (update $VERSION)"
poll=0
announced=0
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

  if (( poll % ANNOUNCE_EVERY == 0 )); then
    "$ROOT/scripts/announce-update.sh" "$VERSION" || true
    announced=$((announced + 1))
  fi
  poll=$((poll + 1))
  sleep "$INTERVAL"
done
