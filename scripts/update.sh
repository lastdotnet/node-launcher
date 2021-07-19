#!/usr/bin/env bash

set -e

source ./scripts/core.sh

get_node_info

if ! node_exists; then
  die "No existing THORNode found, make sure this is the correct name"
fi

if snapshot_available; then
  make_snapshot "thornode"
  make_snapshot "bifrost"
fi

source ./scripts/install.sh

echo
echo "=> Waiting for THORNode daemon to be ready"
kubectl rollout status -w deployment/thornode -n "$NAME" --timeout=5m

echo
source ./scripts/set-version.sh
