#!/usr/bin/env bash
# Apply the latest prod client-overlay.zip onto an ATM10 CurseForge/Prism instance.
# Best setup: install official All the Mods 10 (same version as the server), then run this.
set -euo pipefail

REPO="${ATM10_FORK_REPO:-District4k/atm10-server}"
INSTANCE="${1:-${INST_DIR:-${PRISM_INSTANCE_DIR:-}}}"

if [[ -z "$INSTANCE" ]]; then
  cat >&2 <<'EOF'
Usage:
  ./scripts/update-client.sh /path/to/ATM10-instance

Prism Launcher pre-launch command (Settings → Custom commands):
  /Users/enricokallaste/atm10-server/scripts/update-client.sh "$INST_DIR"

Optional:
  ATM10_FORK_REPO=District4k/atm10-server   (default already)
EOF
  exit 1
fi

if [[ ! -d "$INSTANCE" ]]; then
  echo "[client] instance folder does not exist: $INSTANCE" >&2
  exit 1
fi

# Sanity: looks like a Minecraft instance
if [[ ! -d "$INSTANCE/mods" && ! -f "$INSTANCE/minecraftinstance.json" && ! -f "$INSTANCE/instance.cfg" ]]; then
  echo "[client] warning: $INSTANCE does not look like a launcher instance (continuing)" >&2
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

API="https://api.github.com/repos/${REPO}/releases/latest"
echo "[client] fetching latest release from $REPO"
JSON="$(curl -fsSL "$API")" || {
  echo "[client] could not read $API — is there a published Release yet?" >&2
  exit 1
}

ASSET_URL="$(printf '%s' "$JSON" | python3 -c '
import json,sys
d=json.load(sys.stdin)
assets=d.get("assets") or []
hits=[a for a in assets if a.get("name")=="client-overlay.zip"]
print(hits[0]["browser_download_url"] if hits else "")
')"
TAG="$(printf '%s' "$JSON" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("tag_name",""))')"

if [[ -z "$ASSET_URL" ]]; then
  echo "[client] latest release has no client-overlay.zip asset" >&2
  exit 1
fi

echo "[client] downloading $TAG → client-overlay.zip"
curl -fsSL -o "$TMP/client-overlay.zip" "$ASSET_URL"
mkdir -p "$INSTANCE/mods" "$INSTANCE/config"
unzip -o "$TMP/client-overlay.zip" -d "$INSTANCE"
echo "[client] OK — overlay $TAG applied to $INSTANCE"
echo "[client] Launch with the same ATM10 CurseForge version as the server (see VERSION in the release)."
