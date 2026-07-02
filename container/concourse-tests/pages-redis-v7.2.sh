#!/bin/bash
set -e

echo "  → Testing pages-redis-v7.2 in Concourse context"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/service-helpers.sh
. "$SCRIPT_DIR/lib/service-helpers.sh"

service_setup_workspace

# pages-redis-v7.2 packages Redis 7.2 (built from source). The server is
# started at runtime with networking; we do not start it. Verify the server
# and client binaries are present and report versions.
echo "  → Testing redis-server"
require_commands redis-server

echo "  ✓ redis-server: $(redis-server --version 2>&1 | head -1)"

echo "  → Testing redis-cli"
if command -v redis-cli >/dev/null 2>&1; then
  echo "  ✓ redis-cli: $(redis-cli --version 2>&1)"
else
  echo "  ℹ redis-cli not present (server-only image?)"
fi

assert_workspace_io

echo "  ✓ pages-redis-v7.2 Concourse validation passed"
echo "  ℹ Note: redis server not started in smoke test"
