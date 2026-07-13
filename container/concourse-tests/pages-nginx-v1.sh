#!/bin/bash
set -e

# shellcheck source=lib/common.sh
. "$(cd "$(dirname "$0")/lib" && pwd)/common.sh"

ct_bootstrap pages-nginx-v1 runtime

# pages-nginx-v1 is built on openresty; run_nginx_tests handles both binaries.
run_nginx_tests
