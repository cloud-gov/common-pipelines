#!/bin/bash
set -e

# shellcheck source=lib/common.sh
. "$(cd "$(dirname "$0")/lib" && pwd)/common.sh"

ct_bootstrap bosh-deployment-resource resource

# bosh-deployment-resource deploys/interacts with a BOSH director. Without a
# reachable director the scripts fail; we only validate protocol compliance.
check_protocol '{"source":{"deployment":"test","target":"https://bosh.example.com","client":"admin","client_secret":"fake"},"version":null}'
in_protocol    '{"source":{"deployment":"test","target":"https://bosh.example.com","client":"admin","client_secret":"fake"},"version":{"version":"1"}}'
out_protocol   '{"source":{"deployment":"test","target":"https://bosh.example.com","client":"admin","client_secret":"fake"},"params":{"manifest":"src/manifest.yml"}}'

echo "  ✓ bosh-deployment-resource Concourse protocol validation passed"
