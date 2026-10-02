#!/usr/bin/env bash
# Ensure custom/mods/*.jar exist for overlay builds (jars are gitignored).
# Order: already present → ATM10_EXTRA_MODS_DIR → host Mac path → GitHub extra-mods.zip release.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="$ROOT/custom/mods"
mkdir -p "$DEST"

count_jars() {
  local dir="$1"
  shopt -s nullglob
  local jars=("$dir"/*.jar)
  shopt -u nullglob
  echo "${#jars[@]}"
}

if (($(count_jars "$DEST") > 0)); then
  echo "[seed-mods] custom/mods already has $(count_jars "$DEST") jar(s)"
  exit 0
fi

HOST_DEFAULT="/Users/enricokallaste/atm10-server/custom/mods"
SRC="${ATM10_EXTRA_MODS_DIR:-}"
if [[ -z "$SRC" && -d "$HOST_DEFAULT" && "$(count_jars "$HOST_DEFAULT")" -gt 0 ]]; then
  SRC="$HOST_DEFAULT"
fi

if [[ -n "$SRC" && -d "$SRC" && "$(count_jars "$SRC")" -gt 0 ]]; then
  echo "[seed-mods] copying jars from $SRC"
  cp -f "$SRC"/*.jar "$DEST/"
  echo "[seed-mods] custom/mods now has $(count_jars "$DEST") jar(s)"
  exit 0
fi

REPO="${ATM10_FORK_REPO:-District4k/atm10-server}"
TAG="${ATM10_EXTRA_MODS_TAG:-extra-mods}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "[seed-mods] downloading extra-mods.zip from $REPO@$TAG"
if command -v gh >/dev/null 2>&1; then
  gh release download "$TAG" -R "$REPO" -p extra-mods.zip -D "$TMP"
else
  api="https://api.github.com/repos/${REPO}/releases/tags/${TAG}"
  auth_header=()
  if [[ -n "${GH_TOKEN:-${GITHUB_TOKEN:-}}" ]]; then
    auth_header=(-H "Authorization: Bearer ${GH_TOKEN:-$GITHUB_TOKEN}" -H "Accept: application/vnd.github+json")
  fi
  url="$(curl -fsSL "${auth_header[@]}" "$api" | python3 -c '
import json,sys
d=json.load(sys.stdin)
hits=[a for a in (d.get("assets") or []) if a.get("name")=="extra-mods.zip"]
print(hits[0]["browser_download_url"] if hits else "")
')"
  [[ -n "$url" ]] || {
    echo "[seed-mods] no extra-mods.zip on release $TAG" >&2
    exit 1
  }
  curl -fsSL "${auth_header[@]}" -L -o "$TMP/extra-mods.zip" "$url"
fi

unzip -qo "$TMP/extra-mods.zip" -d "$DEST"
# zip may nest a mods/ folder
if [[ -d "$DEST/mods" ]]; then
  mv -f "$DEST/mods"/*.jar "$DEST/" 2>/dev/null || true
  rm -rf "$DEST/mods"
fi

if (($(count_jars "$DEST") == 0)); then
  cat >&2 <<EOF
[seed-mods] FAILED: no jars in custom/mods after seed.
Put the 12 extras from custom/EXTRA_MODS.md into custom/mods/ on the host,
or publish release tag '$TAG' with asset extra-mods.zip.
EOF
  exit 1
fi

echo "[seed-mods] custom/mods now has $(count_jars "$DEST") jar(s)"
