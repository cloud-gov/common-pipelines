#!/bin/bash
set -e

echo "  → Testing bosh-io-stemcell-resource in Concourse context"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/resource-helpers.sh
. "$SCRIPT_DIR/lib/resource-helpers.sh"

resource_setup_workspace

# bosh-io-stemcell-resource fetches stemcells from bosh.io. It implements check
# and in (fetch-only; no meaningful out). We avoid real network calls, so the
# scripts may exit non-zero; we only assert protocol compliance.
check_protocol '{"source":{"name":"bosh-google-kvm-ubuntu-jammy-go_agent"},"version":null}'
in_protocol    '{"source":{"name":"bosh-google-kvm-ubuntu-jammy-go_agent"},"version":{"version":"1.0"}}'

echo "  ✓ bosh-io-stemcell-resource Concourse protocol validation passed"
