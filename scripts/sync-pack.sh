#!/usr/bin/env bash
# Copy ATM pack files between instance dirs. Never copies world/.
set -euo pipefail

SRC="${1:-}"
DEST="${2:-}"
if [[ -z "$SRC" || -z "$DEST" ]]; then
  echo "Usage: $0 /from-instance /to-instance" >&2
  exit 1
fi
mkdir -p "$DEST"
rsync -a --delete \
  --exclude 'world/' \
  --exclude 'logs/' \
  --exclude 'crash-reports/' \
  --exclude 'session.lock' \
  --exclude '.mixin.out/' \
  --exclude 'libraries-integratedscripting/' \
  --exclude 'dynamic-data-pack-cache/' \
  --exclude '.DS_Store' \
  "$SRC/" "$DEST/"
mkdir -p "$DEST/world" "$DEST/logs"
echo "[sync] pack (no world) $SRC -> $DEST"
