#!/bin/bash
set -e

# shellcheck source=lib/common.sh
. "$(cd "$(dirname "$0")/lib" && pwd)/common.sh"

ct_bootstrap csb-helper service

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
