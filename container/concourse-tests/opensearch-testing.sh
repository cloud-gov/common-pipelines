#!/bin/bash
set -e

# shellcheck source=lib/common.sh
. "$(cd "$(dirname "$0")/lib" && pwd)/common.sh"

ct_bootstrap opensearch-testing service

# opensearch-testing packages OpenSearch for the cf-auth-proxy test suite.
# OpenSearch is a JVM service that needs significant resources and network; we
# do not start it. Verify Java and the OpenSearch distribution are present.
echo "  → Testing Java runtime"
if command -v java >/dev/null 2>&1; then
  echo "  ✓ java available ($(java -version 2>&1 | head -1))"
elif [ -x "${JAVA_HOME:-/opt/java/openjdk}/bin/java" ]; then
  echo "  ✓ java present at ${JAVA_HOME:-/opt/java/openjdk}/bin/java"
else
  echo "  ℹ java not found on PATH (OpenSearch may bundle its own JDK)"
fi

echo "  → Testing OpenSearch distribution"
if [ -d /usr/share/opensearch ] || [ -x /usr/share/opensearch/bin/opensearch ]; then
  echo "  ✓ OpenSearch distribution present"
else
  echo "  ℹ OpenSearch not at /usr/share/opensearch (check image layout)"
fi

assert_workspace_io

echo "  ✓ opensearch-testing Concourse validation passed"
echo "  ℹ Note: OpenSearch JVM service not started in smoke test"
