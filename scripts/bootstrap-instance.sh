#!/usr/bin/env bash
# Copy ATM10 server pack files into a new instance. Never writes to STOCK_PACK.
# Extra jars from custom/mods are applied afterward via apply-overlay.sh.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if [[ -f "$ROOT/deploy.env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "$ROOT/deploy.env"
  set +a
fi

STOCK_PACK="${STOCK_PACK:-/Users/enricokallaste/atm10-stock/ServerFiles-8.2}"
DEST="${1:-}"

if [[ -z "$DEST" ]]; then
  echo "Usage: $0 /path/to/new-instance" >&2
  echo "Example: $0 /Users/enricokallaste/atm10-instances/prod" >&2
  exit 1
fi

DEST="$(mkdir -p "$DEST" && cd "$DEST" && pwd)"
STOCK_PACK="$(cd "$STOCK_PACK" && pwd)"

if [[ "$DEST" == "$STOCK_PACK" || "$DEST" == "$STOCK_PACK"/* ]]; then
  echo "[bootstrap] refusing to write inside stock pack: $STOCK_PACK" >&2
  exit 1
fi

if [[ ! -f "$STOCK_PACK/run.sh" && ! -f "$STOCK_PACK/startserver.sh" ]]; then
  echo "[bootstrap] not an ATM server pack (missing run.sh / startserver.sh): $STOCK_PACK" >&2
  exit 1
fi

echo "[bootstrap] read-only source: $STOCK_PACK"
echo "[bootstrap] new instance:     $DEST"

# --delete drops leftover jars from an older pack; world/ and logs/ are excluded so they stay.
rsync -a --delete \
  --exclude '.DS_Store' \
  --exclude '.idea/' \
  --exclude '.mixin.out/' \
  --exclude 'world/' \
  --exclude 'logs/' \
  --exclude 'crash-reports/' \
  --exclude 'dynamic-data-pack-cache/' \
  --exclude 'libraries-integratedscripting/' \
  --exclude 'journeymap/' \
  --exclude 'blueprints/' \
  --exclude 'usercache.json' \
  --exclude 'usernamecache.json' \
  --exclude 'ops.json' \
  --exclude 'banned-ips.json' \
  --exclude 'banned-players.json' \
  --exclude 'whitelist.json' \
  "$STOCK_PACK/" "$DEST/"

mkdir -p "$DEST/world" "$DEST/logs"
"$ROOT/scripts/apply-overlay.sh" "$DEST"

echo "[bootstrap] done. Start with: cd '$DEST' && ATM10_RESTART=false ./startserver.sh"
echo "[bootstrap] stock pack was not modified."
