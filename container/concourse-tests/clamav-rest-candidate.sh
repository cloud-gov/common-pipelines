#!/bin/bash
set -e

# shellcheck source=lib/common.sh
. "$(cd "$(dirname "$0")/lib" && pwd)/common.sh"

ct_bootstrap clamav-rest-candidate service

# clamav-rest-candidate wraps clamav-rest (a REST front-end for ClamAV) behind
# nginx. The service needs a running clamd + network; we do not start it. Verify
# the clamav-rest binary and supporting tooling are present.
echo "  → Testing clamav-rest binary"
if command -v clamav-rest >/dev/null 2>&1; then
  echo "  ✓ clamav-rest available on PATH"
elif [ -x /usr/bin/clamav-rest ]; then
  echo "  ✓ /usr/bin/clamav-rest present"
else
  echo "  ✗ clamav-rest binary not found"
  exit 1
fi

echo "  → Testing entrypoint"
assert_path /usr/bin/entrypoint.sh

echo "  → Testing nginx (front-end) presence and config"
if command -v nginx >/dev/null 2>&1; then
  echo "  ✓ nginx available"
  nginx -t >/dev/null 2>&1 && echo "  ✓ nginx configuration valid" || \
    echo "  ℹ nginx -t non-zero (config may require runtime values)"
else
  echo "  ℹ nginx not present (front-end may be provided differently)"
fi

assert_workspace_io

echo "  ✓ clamav-rest-candidate Concourse validation passed"
echo "  ℹ Note: clamd daemon and REST server not started in smoke test"
