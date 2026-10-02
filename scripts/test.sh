#!/usr/bin/env bash
# Lightweight checks used on the test branch before promotion to prod.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "[test] VERSION=$(tr -d '[:space:]' < VERSION)"

test -f SERVER.md
test -f scripts/apply-overlay.sh
test -d custom/overrides
test -d kubejs
test -d config

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$TMP/config" "$TMP/mods"
cp config/bcc-common.toml "$TMP/config/" 2>/dev/null || {
  mkdir -p "$TMP/config"
  printf '[general]\n        modpackVersion = "placeholder"\n        modpackName = "x"\n' > "$TMP/config/bcc-common.toml"
}

./scripts/apply-overlay.sh "$TMP"

if [[ ! -f "$TMP/config/bcc-common.toml" ]]; then
  echo "[test] missing bcc-common.toml after overlay" >&2
  exit 1
fi

if ! grep -q "$(tr -d '[:space:]' < VERSION)" "$TMP/config/bcc-common.toml"; then
  echo "[test] overlay did not stamp VERSION into bcc-common.toml" >&2
  exit 1
fi

echo "[test] overlay apply OK"

if [[ "${ENABLE_SMOKE_TEST:-}" == "true" && -n "${TEST_SERVER_DIR:-}" ]]; then
  echo "[test] smoke boot requested"
  exec "$ROOT/scripts/smoke-test.sh"
fi

echo "[test] skipped full Minecraft boot (set ENABLE_SMOKE_TEST=true and TEST_SERVER_DIR for smoke)"
