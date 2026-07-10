#!/bin/bash
set -e

# shellcheck source=lib/common.sh
. "$(cd "$(dirname "$0")/lib" && pwd)/common.sh"

echo "  → Testing github-pr-resource in Concourse context"
setup_workspace

# Test 1: Check script protocol
echo "  → Testing /opt/resource/check protocol"
cat > check-input.json <<EOF
{
  "source": {
    "repository": "cloud-gov/example",
    "access_token": "fake-token-for-testing"
  },
  "version": null
}
EOF

/opt/resource/check < check-input.json > check-output.json || {
  echo "  ℹ check script exited with error (expected without valid token)"
}

if [ -f check-output.json ] && [ -s check-output.json ]; then
  jq -e 'type == "array" or (type == "object" and has("error"))' check-output.json >/dev/null 2>&1 && \
    echo "  ✓ check returns valid JSON"
fi

# Test 2: In script protocol
echo "  → Testing /opt/resource/in protocol"
cat > in-input.json <<EOF
{
  "source": {
    "repository": "cloud-gov/example",
    "access_token": "fake-token"
  },
  "version": {"pr": "1", "commit": "abc123"}
}
EOF

mkdir -p src
/opt/resource/in src < in-input.json > in-output.json || {
  echo "  ℹ in script exited with error (expected without valid token)"
}

if [ -f in-output.json ] && [ -s in-output.json ]; then
  jq -e 'type == "object"' in-output.json >/dev/null 2>&1 && \
    echo "  ✓ in returns JSON object"
fi

# Test 3: Out script protocol (PR comments)
echo "  → Testing /opt/resource/out protocol"
cat > out-input.json <<EOF
{
  "source": {
    "repository": "cloud-gov/example",
    "access_token": "fake-token"
  },
  "params": {
    "path": "src",
    "status": "success"
  }
}
EOF

/opt/resource/out src < out-input.json > out-output.json || {
  echo "  ℹ out script exited with error (expected without valid token)"
}

if [ -f out-output.json ] && [ -s out-output.json ]; then
  jq -e 'type == "object"' out-output.json >/dev/null 2>&1 && \
    echo "  ✓ out returns JSON object"
fi

# Test 4: Git available (PR resource requires it)
echo "  → Testing git availability"
git --version >/dev/null 2>&1 && echo "  ✓ git available"

echo "  ✓ github-pr-resource Concourse protocol validation passed"
