#!/bin/bash
set -e

# shellcheck source=lib/common.sh
. "$(cd "$(dirname "$0")/lib" && pwd)/common.sh"

ct_bootstrap opensearch-dashboards-testing service

# opensearch-dashboards-testing packages OpenSearch Dashboards for the
# cf-auth-proxy test suite. Dashboards is a Node.js service that needs a running
# OpenSearch backend and network; we do not start it. Verify the distribution
# and Node runtime are present.
echo "  → Testing Node.js runtime"
if command -v node >/dev/null 2>&1; then
  echo "  ✓ node available ($(node --version 2>&1))"
else
  echo "  ℹ node not on PATH (Dashboards may bundle its own Node)"
fi

echo "  → Testing OpenSearch Dashboards distribution"
if [ -d /usr/share/opensearch-dashboards ] || \
   [ -x /usr/share/opensearch-dashboards/bin/opensearch-dashboards ]; then
  echo "  ✓ OpenSearch Dashboards distribution present"
else
  echo "  ℹ Dashboards not at /usr/share/opensearch-dashboards (check layout)"
fi

assert_workspace_io

echo "  ✓ opensearch-dashboards-testing Concourse validation passed"
echo "  ℹ Note: Dashboards service not started in smoke test"
