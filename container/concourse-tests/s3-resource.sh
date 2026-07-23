#!/bin/bash
set -e

# shellcheck source=lib/common.sh
. "$(cd "$(dirname "$0")/lib" && pwd)/common.sh"

ct_bootstrap s3-resource resource

# s3-resource pulls/pushes objects from an S3 bucket. Without credentials/network
# the scripts fail; the shared helpers validate protocol compliance and tolerate
# the expected non-zero exit (see lib/resource-helpers.sh).
check_protocol '{"source":{"bucket":"test-bucket","region_name":"us-gov-west-1"},"version":null}'
in_protocol    '{"source":{"bucket":"test-bucket","region_name":"us-gov-west-1"},"version":{"path":"test.txt"},"params":{}}'
out_protocol   '{"source":{"bucket":"test-bucket","region_name":"us-gov-west-1"},"params":{"file":"src/test.txt"}}'

# Test: AWS CLI available (s3-resource requires it)
echo "  → Testing AWS CLI"
aws --version >/dev/null 2>&1 && echo "  ✓ AWS CLI available"

# Test: FIPS endpoint support
echo "  → Testing FIPS endpoint support"
if [ "${AWS_USE_FIPS_ENDPOINT:-}" = "true" ]; then
  echo "  ✓ FIPS endpoint configuration present"
else
  echo "  ⚠ AWS_USE_FIPS_ENDPOINT not set (should be 'true')"
fi

echo "  ✓ s3-resource Concourse protocol validation passed"
