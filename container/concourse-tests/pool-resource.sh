#!/bin/bash
set -e

echo "  → Testing pool-resource in Concourse context"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/resource-helpers.sh
. "$SCRIPT_DIR/lib/resource-helpers.sh"

resource_setup_workspace

# pool-resource manages a pool of locks stored in a git repo. Without a
# reachable repo the scripts fail; we validate protocol compliance and git
# availability.
check_protocol '{"source":{"uri":"https://github.com/cloud-gov/example.git","branch":"main","pool":"test-pool"},"version":null}'
in_protocol    '{"source":{"uri":"https://github.com/cloud-gov/example.git","branch":"main","pool":"test-pool"},"version":{"ref":"abc123"}}'
out_protocol   '{"source":{"uri":"https://github.com/cloud-gov/example.git","branch":"main","pool":"test-pool"},"params":{"acquire":true}}'

echo "  → Testing git availability"
assert_commands git

echo "  ✓ pool-resource Concourse protocol validation passed"
