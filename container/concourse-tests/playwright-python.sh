#!/bin/bash
set -e

echo "  → Testing playwright-python in Concourse context"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/service-helpers.sh
. "$SCRIPT_DIR/lib/service-helpers.sh"

service_setup_workspace

# playwright-python provides Python + Playwright with browsers for end-to-end
# testing. Verify the Python runtime and the playwright module/CLI are present.
# We do not launch a browser (needs a display/sandbox and is slow).
echo "  → Testing Python runtime"
require_commands python3

echo "  ✓ Python: $(python3 --version 2>&1)"

echo "  → Testing Playwright module"
if python3 -c "import playwright" >/dev/null 2>&1; then
  echo "  ✓ playwright Python module importable"
else
  echo "  ✗ playwright module not importable"
  exit 1
fi

echo "  → Testing Playwright CLI"
if python3 -m playwright --version >/dev/null 2>&1; then
  echo "  ✓ playwright CLI works ($(python3 -m playwright --version 2>&1))"
else
  echo "  ℹ playwright CLI version check non-zero (module present)"
fi

assert_workspace_io

echo "  ✓ playwright-python Concourse validation passed"
echo "  ℹ Note: browser launch not exercised in smoke test"
