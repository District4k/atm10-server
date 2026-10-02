#!/usr/bin/env bash
# Warn players, pull prod, overlay, restart the live ATM10 server.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if [[ -f "$ROOT/deploy.env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "$ROOT/deploy.env"
  set +a
fi

SCREEN_SESSION="${SCREEN_SESSION:-atm10}"
LIVE_SERVER_DIR="${LIVE_SERVER_DIR:-$ROOT}"
WARN_SECONDS="${WARN_SECONDS:-60}"
DEPLOY_BRANCH="${DEPLOY_BRANCH:-prod}"

screen_send() {
  screen -S "$SCREEN_SESSION" -X stuff "$1"$'\n'
}

server_running() {
  screen -list 2>/dev/null | grep -q "[.]${SCREEN_SESSION}[[:space:]]" || screen -list 2>/dev/null | grep -q "$SCREEN_SESSION"
}

echo "[deploy] $(date) branch=$DEPLOY_BRANCH dir=$LIVE_SERVER_DIR"

if server_running; then
  if (( WARN_SECONDS > 0 )); then
    screen_send "say §c[Server] Update incoming! Restarting in ${WARN_SECONDS} seconds..."
    sleep $(( WARN_SECONDS / 2 ))
    screen_send "say §c[Server] Restarting in $((WARN_SECONDS / 2)) seconds!"
    sleep $(( WARN_SECONDS / 2 - 10 ))
    screen_send "say §c[Server] Restarting in 10 seconds!"
    sleep 10
  fi
  screen_send "say §c[Server] Restarting now."
  screen_send "stop"
  for i in $(seq 1 90); do
    sleep 1
    if ! server_running; then
      break
    fi
    if [[ "$i" -eq 90 ]]; then
      screen -S "$SCREEN_SESSION" -X quit || true
    fi
  done
fi

cd "$ROOT"
if git remote get-url origin >/dev/null 2>&1; then
  git fetch origin "$DEPLOY_BRANCH"
  git checkout "$DEPLOY_BRANCH"
  git reset --hard "origin/${DEPLOY_BRANCH}"
fi

"$ROOT/scripts/apply-overlay.sh" "$LIVE_SERVER_DIR"

chmod +x "$LIVE_SERVER_DIR/run.sh" "$LIVE_SERVER_DIR/startserver.sh" 2>/dev/null || true

echo "[deploy] starting screen session $SCREEN_SESSION"
if [[ -f "$LIVE_SERVER_DIR/startserver.sh" ]]; then
  screen -dmS "$SCREEN_SESSION" bash -lc "cd '$LIVE_SERVER_DIR' && ATM10_RESTART=false ./startserver.sh"
else
  screen -dmS "$SCREEN_SESSION" bash -lc "cd '$LIVE_SERVER_DIR' && ./run.sh nogui"
fi
echo "[deploy] done"
