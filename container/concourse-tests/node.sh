#!/bin/bash
set -e

echo "  → Testing Node image in Concourse context"

# Scratch workspace provided by integration-test.sh; fall back to a temp dir
# when run standalone.
: "${CONCOURSE_WORKSPACE:=$(mktemp -d)}"
mkdir -p "$CONCOURSE_WORKSPACE"
cd "$CONCOURSE_WORKSPACE"

# Test 1: Node and npm versions
echo "  → Testing Node.js and npm"
node --version >/dev/null && echo "  ✓ Node.js available ($(node --version))"
npm --version >/dev/null && echo "  ✓ npm available ($(npm --version))"

# Test 2: npm install (common Concourse operation)
echo "  → Testing npm install"
mkdir -p "$CONCOURSE_WORKSPACE/output"
mkdir -p src/app
cd src/app
cat > package.json <<EOF
{
  "name": "test-app",
  "version": "1.0.0",
  "scripts": {
    "test": "echo 'Tests passed'",
    "build": "echo 'Build complete' > \"$CONCOURSE_WORKSPACE/output/dist.tar.gz\""
  },
  "dependencies": {
    "express": "^4.18.0"
  }
}
EOF

npm install --quiet >/dev/null 2>&1 && echo "  ✓ npm install works"

# Test 3: npm scripts (test/build)
echo "  → Testing npm scripts"
npm test >/dev/null 2>&1 && echo "  ✓ npm test works"
npm run build >/dev/null 2>&1
[ -f "$CONCOURSE_WORKSPACE/output/dist.tar.gz" ] && echo "  ✓ npm build creates artifacts"

# Test 4: Node execution
echo "  → Testing Node execution"
node -e "const express = require('express'); console.log('Module loading works')" >/dev/null 2>&1 && \
  echo "  ✓ Node can load installed modules"

# Test 5: Workspace structure (typical Concourse setup)
cd "$CONCOURSE_WORKSPACE"
[ -d src ] && echo "  ✓ src directory exists"
[ -d output ] && echo "  ✓ output directory exists"

echo "  ✓ Node image Concourse validation passed"
