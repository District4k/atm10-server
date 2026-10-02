#!/usr/bin/env bash
# Local mirror of GitHub: test pack-check → ff prod → blue-green Docker deploy.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
chmod +x scripts/*.sh docker/entrypoint.sh

echo "[promote] pack tests"
./scripts/test.sh

echo "[promote] fast-forward prod to test"
git checkout prod
git merge --ff-only test

echo "[promote] deploy live Docker (wait for 0 players, then cut over)"
./scripts/deploy.sh

git checkout upgrade
echo "[promote] live cutover used Docker atm10-live (world untouched until empty)"
