#!/bin/bash
set -e

# shellcheck source=lib/common.sh
. "$(cd "$(dirname "$0")/lib" && pwd)/common.sh"

ct_bootstrap pool-resource resource

# pool-resource is git-backed; ensure git never blocks on a credential prompt.
git_noninteractive

# pool-resource manages a pool of locks stored in a git repo. Without a
# reachable repo the scripts fail; we validate protocol compliance and git
# availability.
check_protocol '{"source":{"uri":"https://github.com/cloud-gov/example.git","branch":"main","pool":"test-pool"},"version":null}'
in_protocol    '{"source":{"uri":"https://github.com/cloud-gov/example.git","branch":"main","pool":"test-pool"},"version":{"ref":"abc123"}}'
out_protocol   '{"source":{"uri":"https://github.com/cloud-gov/example.git","branch":"main","pool":"test-pool"},"params":{"acquire":true}}'

echo "  → Testing git availability"
assert_commands git

echo "  ✓ pool-resource Concourse protocol validation passed"
