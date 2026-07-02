#!/bin/bash
set -e

echo "  → Testing s3-simple-resource in Concourse context"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/resource-helpers.sh
. "$SCRIPT_DIR/lib/resource-helpers.sh"

resource_setup_workspace

# s3-simple-resource is a shell-based S3 resource. Without credentials/network
# the scripts fail; we validate protocol compliance and AWS CLI availability.
check_protocol '{"source":{"bucket":"test-bucket","region":"us-gov-west-1"},"version":null}'
in_protocol    '{"source":{"bucket":"test-bucket","region":"us-gov-west-1"},"version":{"path":"test.txt"}}'

echo "test content" > src/test.txt
out_protocol   '{"source":{"bucket":"test-bucket","region":"us-gov-west-1"},"params":{"from":"src/test.txt","to":"/"}}'

echo "  → Testing AWS CLI availability"
assert_commands aws jq

echo "  ✓ s3-simple-resource Concourse protocol validation passed"
