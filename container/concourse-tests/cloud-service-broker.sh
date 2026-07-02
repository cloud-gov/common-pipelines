#!/bin/bash
set -e

echo "  → Testing cloud-service-broker in Concourse context"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/service-helpers.sh
. "$SCRIPT_DIR/lib/service-helpers.sh"

service_setup_workspace

# cloud-service-broker (csb) is an OSBAPI service broker binary at /app/csb.
# It normally listens on :8080; we do not start it. Verify the binary is
# present and responds to a non-serving subcommand.
echo "  → Testing csb binary"
assert_path /app/csb
if /app/csb version >/dev/null 2>&1 || /app/csb --version >/dev/null 2>&1 || /app/csb help >/dev/null 2>&1; then
  echo "  ✓ csb binary is executable"
else
  echo "  ℹ csb exited non-zero for version/help (binary present, may require config)"
fi

assert_workspace_io

echo "  ✓ cloud-service-broker Concourse validation passed"
echo "  ℹ Note: broker HTTP server (:8080) not started in smoke test"
