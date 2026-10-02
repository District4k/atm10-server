#!/usr/bin/env bash
# Download the latest prod client overlay from GitHub into a Prism/CurseForge instance.
set -euo pipefail

INSTANCE="${1:-}"
REPO="${ATM10_FORK_REPO:-}"

if [[ -z "$INSTANCE" ]]; then
  echo "Usage: ATM10_FORK_REPO=owner/atm10-server $0 /path/to/minecraft-instance" >&2
  exit 1
fi

if [[ -z "$REPO" ]]; then
  echo "Set ATM10_FORK_REPO to owner/name (your GitHub fork), e.g. District4k/atm10-server" >&2
  exit 1
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

API="https://api.github.com/repos/${REPO}/releases/latest"
echo "[client] fetching $API"
ASSET_URL="$(curl -fsSL "$API" | python3 -c 'import json,sys; d=json.load(sys.stdin); assets=d.get("assets") or [];
hits=[a for a in assets if a.get("name")=="client-overlay.zip"]
print(hits[0]["browser_download_url"] if hits else "")')"

if [[ -z "$ASSET_URL" ]]; then
  echo "[client] no client-overlay.zip on the latest GitHub Release" >&2
  exit 1
fi

curl -fsSL -o "$TMP/client-overlay.zip" "$ASSET_URL"
unzip -o "$TMP/client-overlay.zip" -d "$INSTANCE"
echo "[client] updated $INSTANCE from $REPO"
