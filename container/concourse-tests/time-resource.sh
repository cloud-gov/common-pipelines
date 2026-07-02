#!/bin/bash
set -e

echo "  → Testing time-resource in Concourse context"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/resource-helpers.sh
. "$SCRIPT_DIR/lib/resource-helpers.sh"

resource_setup_workspace

# time-resource emits a version on a schedule/interval. check and in evaluate
# locally (no network), so they should succeed and return protocol-compliant
# JSON. There is no meaningful out.
check_protocol '{"source":{"interval":"1m","location":"America/New_York"},"version":null}'
in_protocol    '{"source":{"interval":"1m","location":"America/New_York"},"version":{"time":"2020-01-01T00:00:00Z"}}'

echo "  ✓ time-resource Concourse protocol validation passed"
echo "  ℹ Note: time-resource has no meaningful /opt/resource/out"
