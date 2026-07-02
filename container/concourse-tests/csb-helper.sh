#!/bin/bash
set -e

echo "  → Testing csb-helper in Concourse context"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/service-helpers.sh
. "$SCRIPT_DIR/lib/service-helpers.sh"

service_setup_workspace

# csb-helper is a small Go helper binary (default CMD "helper"). Verify it is
# present on PATH or at /app/helper and is executable.
echo "  → Testing helper binary"
if command -v helper >/dev/null 2>&1; then
  echo "  ✓ helper available on PATH"
  helper --help >/dev/null 2>&1 || helper -h >/dev/null 2>&1 || \
    echo "  ℹ helper exited non-zero for --help (binary present)"
elif [ -x /app/helper ]; then
  echo "  ✓ /app/helper present and executable"
  /app/helper --help >/dev/null 2>&1 || /app/helper -h >/dev/null 2>&1 || \
    echo "  ℹ /app/helper exited non-zero for --help (binary present)"
else
  echo "  ✗ helper binary not found on PATH or at /app/helper"
  exit 1
fi

assert_workspace_io

echo "  ✓ csb-helper Concourse validation passed"
