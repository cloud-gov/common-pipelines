#!/bin/bash
set -e

echo "  → Testing pages-python-v3.11 in Concourse context"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/runtime-helpers.sh
. "$SCRIPT_DIR/lib/runtime-helpers.sh"

run_python_tests
