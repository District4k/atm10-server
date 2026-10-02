#!/usr/bin/env bash
# Ensure live server.properties has RCON enabled (password from deploy.env / env).
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

LIVE_SERVER_DIR="${LIVE_SERVER_DIR:-/Users/enricokallaste/atm10-instances/prod}"
PROPS="$LIVE_SERVER_DIR/server.properties"
PASSWORD="${RCON_PASSWORD:-}"
PORT="${RCON_PORT:-25575}"

if [[ -z "$PASSWORD" ]]; then
  echo "[rcon] RCON_PASSWORD not set — in-game update notices disabled" >&2
  exit 1
fi

if [[ ! -f "$PROPS" ]]; then
  echo "[rcon] missing $PROPS" >&2
  exit 1
fi

set_prop() {
  local key="$1" val="$2"
  if grep -q "^${key}=" "$PROPS"; then
    sed -i.bak -E "s|^${key}=.*|${key}=${val}|" "$PROPS"
  else
    printf '%s=%s\n' "$key" "$val" >> "$PROPS"
  fi
}

set_prop enable-rcon true
set_prop rcon.password "$PASSWORD"
set_prop rcon.port "$PORT"
rm -f "$PROPS.bak"
echo "[rcon] enabled on $PROPS (port $PORT)"
