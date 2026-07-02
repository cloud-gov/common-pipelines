#!/bin/bash
set -e

echo "  → Testing concourse-rwlock-resource in Concourse context"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/resource-helpers.sh
. "$SCRIPT_DIR/lib/resource-helpers.sh"

resource_setup_workspace

# rwlock resource manages read/write locks in a git repo. Without a reachable
# repo the scripts fail; we validate protocol compliance and git availability.
check_protocol '{"source":{"uri":"https://github.com/cloud-gov/example.git","branch":"main"},"version":null}'
in_protocol    '{"source":{"uri":"https://github.com/cloud-gov/example.git","branch":"main"},"version":{"ref":"abc123"}}'
out_protocol   '{"source":{"uri":"https://github.com/cloud-gov/example.git","branch":"main"},"params":{"acquire":true}}'

echo "  → Testing git availability"
assert_commands git

echo "  ✓ concourse-rwlock-resource Concourse protocol validation passed"
