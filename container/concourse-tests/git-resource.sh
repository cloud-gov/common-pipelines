#!/bin/bash
set -e

echo "  → Testing git-resource in Concourse context"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/resource-helpers.sh
. "$SCRIPT_DIR/lib/resource-helpers.sh"

resource_setup_workspace

# git-resource clones/checks git repositories. Without network access the
# scripts fail; we validate protocol compliance and git availability.
check_protocol '{"source":{"uri":"https://github.com/cloud-gov/example.git","branch":"main"},"version":null}'
in_protocol    '{"source":{"uri":"https://github.com/cloud-gov/example.git","branch":"main"},"version":{"ref":"abc123"}}'
out_protocol   '{"source":{"uri":"https://github.com/cloud-gov/example.git","branch":"main"},"params":{"repository":"src"}}'

echo "  → Testing git availability"
assert_commands git

echo "  ✓ git-resource Concourse protocol validation passed"
