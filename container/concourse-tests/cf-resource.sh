#!/bin/bash
set -e

echo "  → Testing cf-resource in Concourse context"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/resource-helpers.sh
. "$SCRIPT_DIR/lib/resource-helpers.sh"

resource_setup_workspace

# cf-resource pushes apps to a Cloud Foundry API. Without a reachable API the
# scripts fail; we validate protocol compliance and that the cf CLI is present.
check_protocol '{"source":{"api":"https://api.example.com","username":"u","password":"p","organization":"o","space":"s"},"version":null}'
in_protocol    '{"source":{"api":"https://api.example.com","username":"u","password":"p","organization":"o","space":"s"},"version":{"timestamp":"0"}}'
out_protocol   '{"source":{"api":"https://api.example.com","username":"u","password":"p","organization":"o","space":"s"},"params":{"manifest":"src/manifest.yml"}}'

echo "  → Testing cf CLI availability"
assert_commands cf

echo "  ✓ cf-resource Concourse protocol validation passed"
