#!/bin/bash
set -e

# shellcheck source=lib/common.sh
. "$(cd "$(dirname "$0")/lib" && pwd)/common.sh"

ct_bootstrap time-resource resource

# time-resource emits a version on a schedule/interval. check and in evaluate
# locally (no network), so they should succeed and return protocol-compliant
# JSON. There is no meaningful out.
check_protocol '{"source":{"interval":"1m","location":"America/New_York"},"version":null}'
in_protocol    '{"source":{"interval":"1m","location":"America/New_York"},"version":{"time":"2020-01-01T00:00:00Z"}}'

echo "  ✓ time-resource Concourse protocol validation passed"
echo "  ℹ Note: time-resource has no meaningful /opt/resource/out"
