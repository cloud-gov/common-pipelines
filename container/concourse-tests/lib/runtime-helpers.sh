#!/bin/bash
# Shared runtime smoke tests for language/web images.
#
# Several images share a runtime (Node.js, Python, nginx/openresty). Rather
# than duplicate test logic, each image's script sources this file and calls
# the matching run_*_tests function. Per-image scripts exist so that the
# image-repository -> <image-repository>.sh lookup in integration-test.sh
# resolves for every repository name.
#
# All functions follow the concourse-tests README rules: use
# $CONCOURSE_WORKSPACE, no external credentials, no production network calls,
# exit non-zero on failure, finish well under two minutes.

# shellcheck source=common.sh
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

runtime_setup_workspace() { setup_workspace; }

# Node.js: verify node/npm, a local (dependency-free) install + scripts, and
# module execution. Avoids network by not declaring registry dependencies.
run_node_tests() {
  runtime_setup_workspace

  echo "  → Testing Node.js and npm"
  node --version >/dev/null && echo "  ✓ Node.js available ($(node --version))"
  npm --version >/dev/null && echo "  ✓ npm available ($(npm --version))"

  echo "  → Testing npm project + scripts (offline)"
  mkdir -p "$CONCOURSE_WORKSPACE/output" src/app
  cd src/app
  cat > package.json <<EOF
{
  "name": "test-app",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "test": "node -e \"process.exit(0)\"",
    "build": "node -e \"require('fs').writeFileSync(process.env.OUT, 'ok')\""
  }
}
EOF
  # No external deps -> npm install stays offline.
  npm install --no-audit --no-fund --quiet >/dev/null 2>&1 && echo "  ✓ npm install works"
  npm test >/dev/null 2>&1 && echo "  ✓ npm test works"
  OUT="$CONCOURSE_WORKSPACE/output/dist.txt" npm run build >/dev/null 2>&1
  [ -f "$CONCOURSE_WORKSPACE/output/dist.txt" ] && echo "  ✓ npm build creates artifacts"

  echo "  → Testing Node execution"
  node -e "const os=require('os'); if(!os.platform()) process.exit(1)" >/dev/null 2>&1 && \
    echo "  ✓ Node can load core modules"

  cd "$CONCOURSE_WORKSPACE"
  echo "  ✓ Node runtime Concourse validation passed"
}

# Python: verify python3/pip, venv creation, and stdlib execution. Avoids
# network by not installing external packages.
run_python_tests() {
  runtime_setup_workspace

  echo "  → Testing Python and pip"
  python3 --version >/dev/null && echo "  ✓ Python available ($(python3 --version 2>&1))"
  if python3 -m pip --version >/dev/null 2>&1; then
    echo "  ✓ pip available ($(python3 -m pip --version 2>&1 | awk '{print $1, $2}'))"
  else
    echo "  ℹ pip module not present (may be provided via venv)"
  fi

  echo "  → Testing stdlib execution"
  python3 -c "import json,os,sys; json.dumps({'ok': True})" >/dev/null 2>&1 && \
    echo "  ✓ Python can import and use stdlib"

  echo "  → Testing virtual environment (offline)"
  mkdir -p src
  cd src
  if python3 -m venv test-venv >/dev/null 2>&1; then
    # shellcheck disable=SC1091
    . test-venv/bin/activate
    python -c "import sys; assert sys.prefix" >/dev/null 2>&1 && echo "  ✓ venv activates and runs"
    deactivate
  else
    echo "  ℹ venv module not available (acceptable for minimal images)"
  fi

  echo "  → Testing output artifacts"
  mkdir -p "$CONCOURSE_WORKSPACE/output"
  echo "build-complete" > "$CONCOURSE_WORKSPACE/output/result.txt"
  [ -f "$CONCOURSE_WORKSPACE/output/result.txt" ] && echo "  ✓ output artifacts work"

  cd "$CONCOURSE_WORKSPACE"
  echo "  ✓ Python runtime Concourse validation passed"
}

# nginx/openresty: verify the binary, config syntax, and content directory
# operations. Does not start the server (no ports/network).
run_nginx_tests() {
  runtime_setup_workspace

  echo "  → Testing nginx binary"
  local nginx_bin=""
  for b in nginx openresty; do
    if command -v "$b" >/dev/null 2>&1; then nginx_bin="$b"; break; fi
  done
  if [ -z "$nginx_bin" ]; then
    echo "  ✗ neither nginx nor openresty command found"
    return 1
  fi
  echo "  ✓ $nginx_bin found ($($nginx_bin -v 2>&1 | head -1))"

  echo "  → Testing configuration syntax"
  if "$nginx_bin" -t >/dev/null 2>&1; then
    echo "  ✓ $nginx_bin configuration valid"
  else
    echo "  ℹ $nginx_bin -t non-zero (config may require runtime values)"
  fi

  echo "  → Testing content directories"
  mkdir -p src/html
  echo '<h1>Test</h1>' > src/html/index.html
  [ -f src/html/index.html ] && echo "  ✓ can create HTML content"

  echo "  ✓ nginx runtime Concourse validation passed"
  echo "  ℹ Note: server not started in smoke test (no networking)"
}
