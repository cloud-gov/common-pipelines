#!/bin/bash
set -e

# shellcheck source=lib/common.sh
. "$(cd "$(dirname "$0")/lib" && pwd)/common.sh"

ct_bootstrap bosh-io-release-resource resource

# bosh-io-release-resource fetches releases from bosh.io. It implements check
# and in (fetch-only; no meaningful out). We avoid real network calls, so the
# scripts may exit non-zero; we only assert protocol compliance.
check_protocol '{"source":{"repository":"cloudfoundry/bosh"},"version":null}'
in_protocol    '{"source":{"repository":"cloudfoundry/bosh"},"version":{"version":"1.0"}}'

echo "  ✓ bosh-io-release-resource Concourse protocol validation passed"
