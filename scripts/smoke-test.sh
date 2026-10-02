#!/usr/bin/env bash
# Optional: start the staging server until it reports done, then stop it.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if [[ -f "$ROOT/deploy.env" ]]; then
  # shellcheck disable=SC1091
  set -a
  source "$ROOT/deploy.env"
  set +a
fi

TEST_SERVER_DIR="${TEST_SERVER_DIR:?Set TEST_SERVER_DIR in deploy.env}"
SCREEN_SESSION="${TEST_SCREEN_SESSION:-atm10-test}"
TIMEOUT="${SMOKE_TIMEOUT_SECONDS:-300}"

if [[ ! -f "$TEST_SERVER_DIR/run.sh" && ! -f "$TEST_SERVER_DIR/startserver.sh" ]]; then
  echo "[smoke] no startserver.sh/run.sh in $TEST_SERVER_DIR" >&2
  exit 1
fi

"$ROOT/scripts/apply-overlay.sh" "$TEST_SERVER_DIR"

if screen -list | grep -q "$SCREEN_SESSION"; then
  screen -S "$SCREEN_SESSION" -X stuff "stop"$'\n' || true
  sleep 15
  screen -S "$SCREEN_SESSION" -X quit || true
fi

LOG="$TEST_SERVER_DIR/logs/latest.log"
rm -f "$LOG"
screen -dmS "$SCREEN_SESSION" bash -lc "cd '$TEST_SERVER_DIR' && ATM10_RESTART=false ./startserver.sh"

echo "[smoke] waiting up to ${TIMEOUT}s for server ready..."
deadline=$((SECONDS + TIMEOUT))
while (( SECONDS < deadline )); do
  if [[ -f "$LOG" ]] && grep -Eqi 'Done \(|Dedicated server took' "$LOG"; then
    echo "[smoke] server reported ready"
    screen -S "$SCREEN_SESSION" -X stuff "stop"$'\n' || true
    sleep 20
    screen -S "$SCREEN_SESSION" -X quit || true
    exit 0
  fi
  sleep 5
done

echo "[smoke] timed out; last log lines:" >&2
tail -n 40 "$LOG" >&2 || true
screen -S "$SCREEN_SESSION" -X stuff "stop"$'\n' || true
sleep 10
screen -S "$SCREEN_SESSION" -X quit || true
exit 1
