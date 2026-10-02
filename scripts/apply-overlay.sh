#!/usr/bin/env bash
# Copy custom overrides, extra mods, and pack version onto an ATM-10 instance.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="${1:-}"

if [[ -z "$DEST" ]]; then
  echo "Usage: $0 /path/to/minecraft-instance" >&2
  exit 1
fi

if [[ ! -d "$DEST" ]]; then
  echo "Destination does not exist: $DEST" >&2
  exit 1
fi

VERSION="$(tr -d '[:space:]' < "$ROOT/VERSION")"
OVERRIDES="$ROOT/custom/overrides"

if [[ -d "$OVERRIDES" ]]; then
  echo "[overlay] rsync overrides -> $DEST"
  rsync -a --exclude 'README.md' "$OVERRIDES/" "$DEST/"
fi

if [[ -d "$ROOT/custom/mods" ]]; then
  mkdir -p "$DEST/mods"
  shopt -s nullglob
  jars=("$ROOT/custom/mods"/*.jar)
  if ((${#jars[@]})); then
    echo "[overlay] copy extra mods (${#jars[@]}) -> $DEST/mods"
    cp -f "${jars[@]}" "$DEST/mods/"
  fi
  shopt -u nullglob
fi

if [[ -d "$ROOT/custom/client-mods" && "${APPLY_CLIENT_MODS:-0}" == "1" ]]; then
  mkdir -p "$DEST/mods"
  shopt -s nullglob
  jars=("$ROOT/custom/client-mods"/*.jar)
  if ((${#jars[@]})); then
    echo "[overlay] copy client mods (${#jars[@]}) -> $DEST/mods"
    cp -f "${jars[@]}" "$DEST/mods/"
  fi
  shopt -u nullglob
fi

REMOVE_LIST="$ROOT/custom/remove-mods.txt"
if [[ -f "$REMOVE_LIST" && -d "$DEST/mods" ]]; then
  while IFS= read -r pattern || [[ -n "$pattern" ]]; do
    [[ -z "$pattern" || "$pattern" =~ ^# ]] && continue
    shopt -s nullglob
    for f in "$DEST/mods"/$pattern; do
      echo "[overlay] remove $f"
      rm -f "$f"
    done
    shopt -u nullglob
  done < "$REMOVE_LIST"
fi

BCC="$DEST/config/bcc-common.toml"
if [[ -f "$BCC" ]]; then
  echo "[overlay] stamp Better Compatibility Checker version $VERSION"
  if grep -q 'modpackVersion' "$BCC"; then
    sed -i.bak -E "s/modpackVersion = \".*\"/modpackVersion = \"${VERSION}\"/" "$BCC"
    rm -f "$BCC.bak"
  fi
  if grep -q 'modpackName' "$BCC"; then
    sed -i.bak -E 's/modpackName = ".*"/modpackName = "ATM10 (custom fork)"/' "$BCC"
    rm -f "$BCC.bak"
  fi
fi

echo "[overlay] done ($VERSION) -> $DEST"
