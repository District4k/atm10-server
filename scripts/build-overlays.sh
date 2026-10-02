#!/usr/bin/env bash
# Build client-overlay.zip and server-overlay.zip (ATM10 already installed on the instance).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
VERSION="$(tr -d '[:space:]' < VERSION)"
OUT="$ROOT/dist"
rm -rf "$OUT"
mkdir -p "$OUT/client/config" "$OUT/server/config"

if [[ -f config/bcc-common.toml ]]; then
  cp config/bcc-common.toml "$OUT/client/config/"
  cp config/bcc-common.toml "$OUT/server/config/"
fi

APPLY_CLIENT_MODS=1 "$ROOT/scripts/apply-overlay.sh" "$OUT/client"
APPLY_CLIENT_MODS=0 "$ROOT/scripts/apply-overlay.sh" "$OUT/server"

(
  cd "$OUT/client"
  zip -qr "$OUT/client-overlay.zip" .
)
(
  cd "$OUT/server"
  zip -qr "$OUT/server-overlay.zip" .
)

echo "$VERSION" > "$OUT/VERSION"
ls -lh "$OUT"/*.zip
