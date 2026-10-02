#!/bin/sh
set -eu
cd /data

if [ ! -f startserver.sh ]; then
  echo "atm10-entrypoint: missing /data/startserver.sh (is LIVE_SERVER_DIR mounted?)" >&2
  exit 1
fi

chmod +x startserver.sh run.sh 2>/dev/null || true
export ATM10_RESTART="${ATM10_RESTART:-false}"

if [ ! -d libraries ]; then
  echo "atm10-entrypoint: installing NeoForge (libraries missing)"
  ATM10_INSTALL_ONLY=true ./startserver.sh
fi

exec ./startserver.sh
