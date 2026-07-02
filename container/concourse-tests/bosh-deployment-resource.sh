#!/bin/bash
set -e

echo "  → Testing bosh-deployment-resource in Concourse context"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/resource-helpers.sh
. "$SCRIPT_DIR/lib/resource-helpers.sh"

resource_setup_workspace

# bosh-deployment-resource deploys/interacts with a BOSH director. Without a
# reachable director the scripts fail; we only validate protocol compliance.
check_protocol '{"source":{"deployment":"test","target":"https://bosh.example.com","client":"admin","client_secret":"fake"},"version":null}'
in_protocol    '{"source":{"deployment":"test","target":"https://bosh.example.com","client":"admin","client_secret":"fake"},"version":{"version":"1"}}'
out_protocol   '{"source":{"deployment":"test","target":"https://bosh.example.com","client":"admin","client_secret":"fake"},"params":{"manifest":"src/manifest.yml"}}'

echo "  ✓ bosh-deployment-resource Concourse protocol validation passed"
