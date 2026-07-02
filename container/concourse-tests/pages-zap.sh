#!/bin/bash
set -e

echo "  → Testing pages-zap in Concourse context"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/service-helpers.sh
. "$SCRIPT_DIR/lib/service-helpers.sh"

service_setup_workspace

# pages-zap packages OWASP ZAP (a Java DAST tool). ZAP needs a JVM and, for a
# real scan, a target and network. We only verify the runtime and launcher.
echo "  → Testing Java runtime"
if command -v java >/dev/null 2>&1; then
  echo "  ✓ java available ($(java -version 2>&1 | head -1))"
elif [ -x "${JAVA_HOME:-/opt/java/openjdk}/bin/java" ]; then
  echo "  ✓ java present at ${JAVA_HOME:-/opt/java/openjdk}/bin/java"
else
  echo "  ✗ java not found"
  exit 1
fi

echo "  → Testing ZAP launcher"
if command -v zap.sh >/dev/null 2>&1 || [ -x /zap/zap.sh ]; then
  echo "  ✓ zap.sh present"
else
  echo "  ℹ zap.sh not found by common paths (verify image layout)"
fi

assert_workspace_io

echo "  ✓ pages-zap Concourse validation passed"
echo "  ℹ Note: ZAP scan against a target not exercised in smoke test"
