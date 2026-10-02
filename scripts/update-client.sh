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

Defaults to GitHub repo District4k/atm10-server.
If the repo is private, set GH_TOKEN (or run while logged in with gh).
EOF
  exit 1
fi

if [[ ! -d "$INSTANCE" ]]; then
  echo "[client] instance folder does not exist: $INSTANCE" >&2
  exit 1
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
ZIP="$TMP/client-overlay.zip"

download_with_gh() {
  command -v gh >/dev/null 2>&1 || return 1
  echo "[client] downloading via gh (authenticated)"
  gh release download -R "$REPO" -p client-overlay.zip -D "$TMP" >/dev/null
  # gh may name the file client-overlay.zip in TMP
  [[ -f "$ZIP" ]] || mv "$TMP"/client-overlay.zip "$ZIP" 2>/dev/null || true
  [[ -f "$ZIP" ]]
}

download_with_curl() {
  local api asset_url tag auth_header=()
  api="https://api.github.com/repos/${REPO}/releases/latest"
  if [[ -n "${GH_TOKEN:-${GITHUB_TOKEN:-}}" ]]; then
    auth_header=(-H "Authorization: Bearer ${GH_TOKEN:-$GITHUB_TOKEN}" -H "Accept: application/vnd.github+json")
  fi
  echo "[client] fetching latest release from $REPO"
  local json
  json="$(curl -fsSL "${auth_header[@]}" "$api")" || return 1
  asset_url="$(printf '%s' "$json" | python3 -c '
import json,sys
d=json.load(sys.stdin)
assets=d.get("assets") or []
hits=[a for a in assets if a.get("name")=="client-overlay.zip"]
print(hits[0]["browser_download_url"] if hits else "")
')"
  tag="$(printf '%s' "$json" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("tag_name",""))')"
  [[ -n "$asset_url" ]] || return 1
  echo "[client] downloading $tag → client-overlay.zip"
  curl -fsSL "${auth_header[@]}" -o "$ZIP" -L "$asset_url"
}

if ! download_with_gh; then
  if ! download_with_curl; then
    cat >&2 <<EOF
[client] could not download client-overlay.zip from $REPO

If the repo is private:
  - run: gh auth login
  - or:  export GH_TOKEN=...   (classic token with repo scope)
Or make the GitHub repo public so friends can update without a token.
EOF
    exit 1
  fi
fi

mkdir -p "$INSTANCE/mods" "$INSTANCE/config"
unzip -o "$ZIP" -d "$INSTANCE"
echo "[client] OK — overlay applied to $INSTANCE"
echo "[client] Use the same official ATM10 CurseForge version as the server."
