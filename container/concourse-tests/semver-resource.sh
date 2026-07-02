#!/bin/bash
set -e

echo "  → Testing semver-resource in Concourse context"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/resource-helpers.sh
. "$SCRIPT_DIR/lib/resource-helpers.sh"

resource_setup_workspace

# semver-resource manages a semantic version stored in a backing driver
# (git/s3/etc). Without a reachable backend the scripts fail; we validate
# protocol compliance.
check_protocol '{"source":{"driver":"git","uri":"https://github.com/cloud-gov/example.git","branch":"version","file":"version"},"version":null}'
in_protocol    '{"source":{"driver":"git","uri":"https://github.com/cloud-gov/example.git","branch":"version","file":"version"},"version":{"number":"1.0.0"}}'
out_protocol   '{"source":{"driver":"git","uri":"https://github.com/cloud-gov/example.git","branch":"version","file":"version"},"params":{"bump":"patch"}}'

echo "  ✓ semver-resource Concourse protocol validation passed"
