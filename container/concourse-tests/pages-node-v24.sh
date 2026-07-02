#!/bin/bash
set -e

echo "  → Testing pages-node-v24 in Concourse context"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/runtime-helpers.sh
. "$SCRIPT_DIR/lib/runtime-helpers.sh"

run_node_tests
