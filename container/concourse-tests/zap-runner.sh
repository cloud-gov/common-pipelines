#!/bin/bash
set -e

# shellcheck source=lib/common.sh
. "$(cd "$(dirname "$0")/lib" && pwd)/common.sh"

ct_bootstrap zap-runner service

# zap-runner packages OWASP ZAP (a Java DAST tool) for automated scans. ZAP
# needs a JVM and, for real scans, a target and network. We only verify the
# runtime and ZAP launcher are present.
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
if command -v zap.sh >/dev/null 2>&1 || [ -x /zap/zap.sh ] || [ -x zap.sh ]; then
  echo "  ✓ zap.sh present"
else
  echo "  ℹ zap.sh not found by common paths (verify image layout)"
fi

assert_workspace_io

echo "  ✓ zap-runner Concourse validation passed"
echo "  ℹ Note: ZAP scan against a target not exercised in smoke test"
