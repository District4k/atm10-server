#!/usr/bin/env bash
# Build client-overlay.zip and server-overlay.zip (ATM10 already installed on the instance).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
VERSION="$(tr -d '[:space:]' < VERSION)"
OUT="$ROOT/dist"

# Jars are gitignored; seed from host path or the extra-mods GitHub release before packaging.
chmod +x "$ROOT/scripts/seed-extra-mods.sh"
"$ROOT/scripts/seed-extra-mods.sh"

rm -rf "$OUT"
mkdir -p "$OUT/client/config" "$OUT/server/config"

if [[ -f config/bcc-common.toml ]]; then
  cp config/bcc-common.toml "$OUT/client/config/"
  cp config/bcc-common.toml "$OUT/server/config/"
fi

APPLY_CLIENT_MODS=1 "$ROOT/scripts/apply-overlay.sh" "$OUT/client"
APPLY_CLIENT_MODS=0 "$ROOT/scripts/apply-overlay.sh" "$OUT/server"

# Guard: empty mods/ is what broke GlitchCore sync for Prism clients (prod-3 was configs-only).
shopt -s nullglob
client_jars=("$OUT/client/mods"/*.jar)
server_jars=("$OUT/server/mods"/*.jar)
shopt -u nullglob
if ((${#client_jars[@]} == 0)) || ((${#server_jars[@]} == 0)); then
  echo "[build-overlays] ERROR: overlay mods/ is empty (client=${#client_jars[@]} server=${#server_jars[@]})." >&2
  echo "[build-overlays] Clients would miss GlitchCore/SereneSeasons and get kicked on join." >&2
  exit 1
fi
if [[ ! -f "$OUT/client/mods/GlitchCore-neoforge-1.21.1-2.1.0.2.jar" ]]; then
  echo "[build-overlays] ERROR: missing GlitchCore-neoforge-1.21.1-2.1.0.2.jar in client overlay." >&2
  exit 1
fi

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
echo "[build-overlays] client jars: ${#client_jars[@]}  server jars: ${#server_jars[@]}"
