#!/bin/bash
set -e

echo "  → Testing pages-nginx-v1 in Concourse context"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/runtime-helpers.sh
. "$SCRIPT_DIR/lib/runtime-helpers.sh"

# pages-nginx-v1 is built on openresty; run_nginx_tests handles both binaries.
run_nginx_tests
