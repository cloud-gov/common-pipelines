#!/bin/bash
set -e

# shellcheck source=lib/common.sh
. "$(cd "$(dirname "$0")/lib" && pwd)/common.sh"

ct_bootstrap github-pr-resource resource

# github-pr-resource lists/fetches/updates GitHub pull requests. Without a valid
# token/network the scripts fail; the shared helpers validate protocol
# compliance and tolerate the expected non-zero exit (see
# lib/resource-helpers.sh).
check_protocol '{"source":{"repository":"cloud-gov/example","access_token":"fake-token-for-testing"},"version":null}'
in_protocol    '{"source":{"repository":"cloud-gov/example","access_token":"fake-token"},"version":{"pr":"1","commit":"abc123"}}'
out_protocol   '{"source":{"repository":"cloud-gov/example","access_token":"fake-token"},"params":{"path":"src","status":"success"}}'

# Test: git available (PR resource requires it)
echo "  → Testing git availability"
git --version >/dev/null 2>&1 && echo "  ✓ git available"

echo "  ✓ github-pr-resource Concourse protocol validation passed"
