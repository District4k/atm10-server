#!/usr/bin/env bash
# Blue-green prod deploy: prepare next while live stays up, cut over only at 0 players,
# roll back pack files (never the world) if the new live boot fails.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
load_env() {
  local f
  for f in "$ROOT/deploy.env" "$ROOT/.env"; do
    if [[ -f "$f" ]]; then
      set -a
      # shellcheck disable=SC1090
      source "$f"
      set +a
    fi
  done
}
load_env

LIVE_SERVER_DIR="${LIVE_SERVER_DIR:-/Users/enricokallaste/atm10-instances/prod}"
NEXT_SERVER_DIR="${NEXT_SERVER_DIR:-/Users/enricokallaste/atm10-instances/prod-next}"
SNAPSHOT_DIR="${SNAPSHOT_DIR:-/Users/enricokallaste/atm10-instances/prod-snapshot}"
STATUS_HOST="${STATUS_HOST:-127.0.0.1}"
MC_PORT="${MC_PORT:-25565}"
NEXT_PORT="${NEXT_PORT:-25566}"
DEPLOY_BRANCH="${DEPLOY_BRANCH:-prod}"
HEALTH_TIMEOUT="${HEALTH_TIMEOUT:-900}"

COMPOSE=(docker compose --project-directory "$ROOT" -f "$ROOT/compose.yaml")
LIVE_CTR=atm10-live
NEXT_CTR=atm10-next

live_running() {
  docker inspect -f '{{.State.Running}}' "$LIVE_CTR" 2>/dev/null | grep -q true
}

if [[ "$NEXT_SERVER_DIR" == "$LIVE_SERVER_DIR" || "$SNAPSHOT_DIR" == "$LIVE_SERVER_DIR" ]]; then
  echo "[deploy] NEXT/SNAPSHOT must not be the live directory" >&2
  exit 1
fi

echo "[deploy] $(date) blue-green  live=$LIVE_SERVER_DIR"

if ! command -v docker >/dev/null 2>&1; then
  echo "[deploy] docker is not installed" >&2
  exit 1
fi

cd "$ROOT"
chmod +x "$ROOT/scripts/"*.sh "$ROOT/docker/entrypoint.sh" "$ROOT/scripts/mc-status.py"

if git remote get-url origin >/dev/null 2>&1; then
  git fetch origin "$DEPLOY_BRANCH"
  git checkout "$DEPLOY_BRANCH"
  git reset --hard "origin/${DEPLOY_BRANCH}"
fi

echo "[deploy] snapshot current pack (no world) -> $SNAPSHOT_DIR"
"$ROOT/scripts/sync-pack.sh" "$LIVE_SERVER_DIR" "$SNAPSHOT_DIR"

echo "[deploy] prepare next instance (live keeps serving)"
rm -rf "$NEXT_SERVER_DIR/world"
"$ROOT/scripts/sync-pack.sh" "$LIVE_SERVER_DIR" "$NEXT_SERVER_DIR"
"$ROOT/scripts/apply-overlay.sh" "$NEXT_SERVER_DIR"
chmod +x "$NEXT_SERVER_DIR/startserver.sh" "$NEXT_SERVER_DIR/run.sh" 2>/dev/null || true
rm -rf "$NEXT_SERVER_DIR/world"
mkdir -p "$NEXT_SERVER_DIR/world" "$NEXT_SERVER_DIR/logs"

echo "[deploy] boot next on :$NEXT_PORT (throwaway world, not the live world)"
"${COMPOSE[@]}" --profile next up -d --build minecraft-next

if ! "$ROOT/scripts/wait-healthy.sh" "$STATUS_HOST" "$NEXT_PORT" "$HEALTH_TIMEOUT"; then
  echo "[deploy] next failed health-check — live unchanged"
  "${COMPOSE[@]}" --profile next stop -t 90 minecraft-next || true
  exit 1
fi

echo "[deploy] next healthy — stopping next to free RAM while live stays up"
"${COMPOSE[@]}" --profile next stop -t 90 minecraft-next || true

NEW_VERSION="$(tr -d '[:space:]' < "$ROOT/VERSION")"
if live_running; then
  echo "[deploy] next is healthy — notifying players and waiting until live has 0 players"
  "$ROOT/scripts/ensure-rcon.sh" || true
  # RCON only applies after a restart; if already enabled, announce now. Otherwise
  # players still see BCC version mismatch on join after cutover.
  UPDATE_VERSION="$NEW_VERSION" "$ROOT/scripts/announce-update.sh" "$NEW_VERSION" || true
  "$ROOT/scripts/wait-empty.sh" "$STATUS_HOST" "$MC_PORT" "$NEW_VERSION"
else
  echo "[deploy] live container is not running — no players to wait for"
fi

echo "[deploy] cut over: stop live, overlay live dir (world stays), start live"
"${COMPOSE[@]}" stop -t 90 minecraft || true

"$ROOT/scripts/apply-overlay.sh" "$LIVE_SERVER_DIR"
chmod +x "$LIVE_SERVER_DIR/startserver.sh" "$LIVE_SERVER_DIR/run.sh" 2>/dev/null || true

"${COMPOSE[@]}" up -d --build minecraft

if "$ROOT/scripts/wait-healthy.sh" "$STATUS_HOST" "$MC_PORT" "$HEALTH_TIMEOUT"; then
  echo "[deploy] live healthy"
  echo "[deploy] done  container=$LIVE_CTR  world=$LIVE_SERVER_DIR/world"
  exit 0
fi

echo "[deploy] new live failed — rolling back pack from snapshot (world untouched)"
"${COMPOSE[@]}" stop -t 90 minecraft || true
"$ROOT/scripts/sync-pack.sh" "$SNAPSHOT_DIR" "$LIVE_SERVER_DIR"
"${COMPOSE[@]}" up -d --build minecraft
"${COMPOSE[@]}" --profile next stop -t 90 minecraft-next || true

if "$ROOT/scripts/wait-healthy.sh" "$STATUS_HOST" "$MC_PORT" "$HEALTH_TIMEOUT"; then
  echo "[deploy] rollback live is healthy" >&2
else
  echo "[deploy] rollback live did not become healthy" >&2
fi
exit 1
