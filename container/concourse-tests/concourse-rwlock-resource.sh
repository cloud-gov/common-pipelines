#!/bin/bash
set -e

# shellcheck source=lib/common.sh
. "$(cd "$(dirname "$0")/lib" && pwd)/common.sh"

ct_bootstrap concourse-rwlock-resource resource

# rwlock resource is git-backed; ensure git never blocks on a credential prompt.
git_noninteractive

# rwlock resource manages read/write locks in a git repo. Without a reachable
# repo the scripts fail; we validate protocol compliance and git availability.
check_protocol '{"source":{"uri":"https://github.com/cloud-gov/example.git","branch":"main"},"version":null}'
in_protocol    '{"source":{"uri":"https://github.com/cloud-gov/example.git","branch":"main"},"version":{"ref":"abc123"}}'
out_protocol   '{"source":{"uri":"https://github.com/cloud-gov/example.git","branch":"main"},"params":{"acquire":true}}'

echo "  → Testing git availability"
assert_commands git

echo "  ✓ concourse-rwlock-resource Concourse protocol validation passed"
