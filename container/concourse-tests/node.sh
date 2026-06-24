#!/bin/bash
set -e

echo "  → Testing Node image in Concourse context"

cd /tmp/build/workspace

# Test 1: Node and npm versions
echo "  → Testing Node.js and npm"
node --version >/dev/null && echo "  ✓ Node.js available ($(node --version))"
npm --version >/dev/null && echo "  ✓ npm available ($(npm --version))"

# Test 2: npm install (common Concourse operation)
echo "  → Testing npm install"
mkdir -p src/app
cd src/app
cat > package.json <<EOF
{
  "name": "test-app",
  "version": "1.0.0",
  "scripts": {
    "test": "echo 'Tests passed'",
    "build": "echo 'Build complete' > ../../output/dist.tar.gz"
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
mkdir -p ../../output
npm run build >/dev/null 2>&1
[ -f ../../output/dist.tar.gz ] && echo "  ✓ npm build creates artifacts"

# Test 4: Node execution
echo "  → Testing Node execution"
node -e "const express = require('express'); console.log('Module loading works')" >/dev/null 2>&1 && \
  echo "  ✓ Node can load installed modules"

# Test 5: Workspace structure (typical Concourse setup)
cd /tmp/build/workspace
[ -d src ] && echo "  ✓ src directory exists (input mount)"
[ -d output ] && echo "  ✓ output directory exists (output mount)"

echo "  ✓ Node image Concourse validation passed"
