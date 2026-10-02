#!/usr/bin/env bash
# Announce a pending update to everyone online on the live server.
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

VERSION="${1:-$(tr -d '[:space:]' < "$ROOT/VERSION" 2>/dev/null || echo unknown)}"
HOST="${RCON_HOST:-127.0.0.1}"
PORT="${RCON_PORT:-25575}"

if [[ -z "${RCON_PASSWORD:-}" ]]; then
  echo "[announce] skip (no RCON_PASSWORD)" >&2
  exit 0
fi

msg="§6[Update] §eVersion §a${VERSION} §eis ready. §7Please log off when you can — the server will update automatically when empty (world is kept)."
if ! python3 "$ROOT/scripts/mc-rcon.py" "$HOST" "$PORT" "say $msg"; then
  echo "[announce] could not send (is live up with RCON?)" >&2
  exit 0
fi
echo "[announce] notified players about $VERSION"
