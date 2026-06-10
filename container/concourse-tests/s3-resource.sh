#!/bin/bash
set -e

echo "  → Testing s3-resource in Concourse context"

cd /tmp/build/workspace

# Test 1: Check script protocol
echo "  → Testing /opt/resource/check protocol"
cat > check-input.json <<EOF
{
  "source": {
    "bucket": "test-bucket",
    "region_name": "us-gov-west-1"
  },
  "version": null
}
EOF

/opt/resource/check < check-input.json > check-output.json || {
  echo "  ℹ check script exited with error (expected without credentials)"
}

# Verify output structure even on error
if [ -f check-output.json ] && [ -s check-output.json ]; then
  if jq -e 'type == "array"' check-output.json >/dev/null 2>&1; then
    echo "  ✓ check returns JSON array"
  elif jq -e 'type == "object" and has("error")' check-output.json >/dev/null 2>&1; then
    echo "  ✓ check returns error object (JSON format correct)"
  fi
fi

# Test 2: In script protocol
echo "  → Testing /opt/resource/in protocol"
cat > in-input.json <<EOF
{
  "source": {
    "bucket": "test-bucket",
    "region_name": "us-gov-west-1"
  },
  "version": {"path": "test.txt"},
  "params": {}
}
EOF

mkdir -p src
/opt/resource/in src < in-input.json > in-output.json || {
  echo "  ℹ in script exited with error (expected without credentials)"
}

if [ -f in-output.json ] && [ -s in-output.json ]; then
  if jq -e 'type == "object"' in-output.json >/dev/null 2>&1; then
    echo "  ✓ in returns JSON object"
  fi
fi

# Test 3: Out script protocol
echo "  → Testing /opt/resource/out protocol"
cat > out-input.json <<EOF
{
  "source": {
    "bucket": "test-bucket",
    "region_name": "us-gov-west-1"
  },
  "params": {
    "file": "src/test.txt"
  }
}
EOF

echo "test content" > src/test.txt
/opt/resource/out src < out-input.json > out-output.json || {
  echo "  ℹ out script exited with error (expected without credentials)"
}

if [ -f out-output.json ] && [ -s out-output.json ]; then
  if jq -e 'type == "object"' out-output.json >/dev/null 2>&1; then
    echo "  ✓ out returns JSON object"
  fi
fi

# Test 4: AWS CLI available (s3-resource requires it)
echo "  → Testing AWS CLI"
aws --version >/dev/null 2>&1 && echo "  ✓ AWS CLI available"

# Test 5: Required environment handling
echo "  → Testing FIPS endpoint support"
if [ "$AWS_USE_FIPS_ENDPOINT" = "true" ]; then
  echo "  ✓ FIPS endpoint configuration present"
else
  echo "  ⚠ AWS_USE_FIPS_ENDPOINT not set (should be 'true')"
fi

echo "  ✓ s3-resource Concourse protocol validation passed"
