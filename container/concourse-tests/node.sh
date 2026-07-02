#!/bin/bash
set -e

echo "  → Testing Node image in Concourse context"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/runtime-helpers.sh
. "$SCRIPT_DIR/lib/runtime-helpers.sh"

run_node_tests
