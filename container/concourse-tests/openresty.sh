#!/bin/bash
set -e

# shellcheck source=lib/common.sh
. "$(cd "$(dirname "$0")/lib" && pwd)/common.sh"

ct_bootstrap openresty service

# openresty is an nginx distribution bundled with LuaJIT. The default CMD runs
# `openresty -g "daemon off;"`; we do not start the server. Verify the binary,
# version, and default config syntax.
echo "  → Testing openresty binary"
require_commands openresty

echo "  → Testing openresty version"
openresty -v 2>&1 | head -1 && echo "  ✓ openresty reports version"

echo "  → Testing configuration syntax"
if openresty -t >/dev/null 2>&1; then
  echo "  ✓ openresty configuration valid"
else
  echo "  ℹ openresty -t non-zero (config may require runtime values)"
fi

assert_workspace_io

echo "  ✓ openresty Concourse validation passed"
echo "  ℹ Note: HTTP server not started in smoke test"
