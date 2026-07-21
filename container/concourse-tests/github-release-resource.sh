#!/bin/bash
set -e

# shellcheck source=lib/common.sh
. "$(cd "$(dirname "$0")/lib" && pwd)/common.sh"

ct_bootstrap github-release-resource resource

# github-release-resource lists/downloads/publishes GitHub releases. Without a
# valid token/network the scripts fail; the shared helpers validate protocol
# compliance and tolerate the expected non-zero exit (see
# lib/resource-helpers.sh).
check_protocol '{"source":{"owner":"cloud-gov","repository":"example","access_token":"fake-token"},"version":null}'
in_protocol    '{"source":{"owner":"cloud-gov","repository":"example","access_token":"fake-token"},"version":{"tag":"v1.0.0"}}'
out_protocol   '{"source":{"owner":"cloud-gov","repository":"example","access_token":"fake-token"},"params":{"name":"v1.0.0","tag":"v1.0.0"}}'

# Test: git available (release resource may need it)
echo "  → Testing git availability"
git --version >/dev/null 2>&1 && echo "  ✓ git available"

echo "  ✓ github-release-resource Concourse protocol validation passed"
