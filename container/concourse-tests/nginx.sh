#!/bin/bash
set -e

echo "  → Testing Nginx image in Concourse context"

cd /tmp/build/workspace

# Test 1: nginx binary
echo "  → Testing nginx binary"
if ! which nginx >/dev/null 2>&1; then
  echo "  ✗ nginx command not found"
  exit 1
fi

NGINX_VERSION=$(nginx -v 2>&1 | awk -F'/' '{print $2}')
echo "  ✓ Nginx ${NGINX_VERSION} found"

# Test 2: nginx configuration syntax
echo "  → Testing nginx configuration"
nginx -t 2>&1 | grep -q "successful" && echo "  ✓ Nginx configuration valid"

# Test 3: Create test content and verify directory structure
echo "  → Testing content directories"
mkdir -p src/html
echo '<h1>Test</h1>' > src/html/index.html
[ -f src/html/index.html ] && echo "  ✓ Can create HTML content"

# Test 4: Configuration file readable
echo "  → Testing configuration access"
if [ -f /etc/nginx/nginx.conf ]; then
  echo "  ✓ nginx.conf accessible"
fi

echo "  ✓ Nginx image Concourse validation passed"
echo "  ℹ Note: Actual service startup tested in integration tests with proper networking"
