#!/bin/bash
set -e

echo "  → Testing cf-cli-resource in Concourse context"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/resource-helpers.sh
. "$SCRIPT_DIR/lib/resource-helpers.sh"

resource_setup_workspace

# cf-cli-resource wraps the cf CLI for Cloud Foundry operations. Without a
# reachable API the scripts fail; we validate protocol compliance and that the
# cf CLI is present.
check_protocol '{"source":{"api":"https://api.example.com","username":"u","password":"p","organization":"o","space":"s"},"version":null}'
in_protocol    '{"source":{"api":"https://api.example.com","username":"u","password":"p","organization":"o","space":"s"},"version":{"timestamp":"0"}}'
out_protocol   '{"source":{"api":"https://api.example.com","username":"u","password":"p","organization":"o","space":"s"},"params":{"command":"push"}}'

echo "  → Testing cf CLI availability"
assert_commands cf jq

echo "  ✓ cf-cli-resource Concourse protocol validation passed"
