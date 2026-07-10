#!/bin/bash
set -e

# shellcheck source=lib/common.sh
. "$(cd "$(dirname "$0")/lib" && pwd)/common.sh"

ct_bootstrap git-resource resource

# git-resource clones/checks git repositories. Without network access the
# scripts fail; we validate protocol compliance and git availability.
check_protocol '{"source":{"uri":"https://github.com/cloud-gov/example.git","branch":"main"},"version":null}'
in_protocol    '{"source":{"uri":"https://github.com/cloud-gov/example.git","branch":"main"},"version":{"ref":"abc123"}}'
out_protocol   '{"source":{"uri":"https://github.com/cloud-gov/example.git","branch":"main"},"params":{"repository":"src"}}'

echo "  → Testing git availability"
assert_commands git

echo "  ✓ git-resource Concourse protocol validation passed"
