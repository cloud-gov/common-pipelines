#!/bin/bash
set -e

echo "  → Testing external-domain-broker-testing in Concourse context"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/service-helpers.sh
. "$SCRIPT_DIR/lib/service-helpers.sh"

service_setup_workspace

# external-domain-broker-testing is a Python test/dev image (Dockerfile.dev)
# used to run the external-domain-broker test suite. Verify the Python runtime
# and common tooling are present; we do not run the full suite (needs network
# and service dependencies).
echo "  → Testing Python runtime"
require_commands python3

echo "  ✓ Python: $(python3 --version 2>&1)"

echo "  → Testing pip / packaging tools"
report_commands pip pip3 pipenv poetry

echo "  → Testing common broker test tooling"
report_commands git openssl

assert_workspace_io

echo "  ✓ external-domain-broker-testing Concourse validation passed"
echo "  ℹ Note: full pytest suite not run (requires service dependencies)"
