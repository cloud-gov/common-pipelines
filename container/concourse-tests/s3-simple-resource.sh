#!/bin/bash
set -e

# shellcheck source=lib/common.sh
. "$(cd "$(dirname "$0")/lib" && pwd)/common.sh"

ct_bootstrap s3-simple-resource resource

# s3-simple-resource is a shell-based S3 resource. Without credentials/network
# the scripts fail; we validate protocol compliance and AWS CLI availability.
check_protocol '{"source":{"bucket":"test-bucket","region":"us-gov-west-1"},"version":null}'
in_protocol    '{"source":{"bucket":"test-bucket","region":"us-gov-west-1"},"version":{"path":"test.txt"}}'

echo "test content" > src/test.txt
out_protocol   '{"source":{"bucket":"test-bucket","region":"us-gov-west-1"},"params":{"from":"src/test.txt","to":"/"}}'

echo "  → Testing AWS CLI availability"
assert_commands aws jq

echo "  ✓ s3-simple-resource Concourse protocol validation passed"
