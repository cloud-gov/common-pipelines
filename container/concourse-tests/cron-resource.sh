#!/bin/bash
set -e

echo "  → Testing cron-resource in Concourse context"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/resource-helpers.sh
. "$SCRIPT_DIR/lib/resource-helpers.sh"

resource_setup_workspace

# cron-resource triggers on a cron expression. It implements check and in only
# (there is no out). check evaluates the schedule locally, so it should succeed
# and return a JSON array.
check_protocol '{"source":{"expression":"* * * * *","location":"America/New_York"},"version":null}'
in_protocol    '{"source":{"expression":"* * * * *","location":"America/New_York"},"version":{"time":"2020-01-01T00:00:00Z"}}'

echo "  ✓ cron-resource Concourse protocol validation passed"
echo "  ℹ Note: cron-resource intentionally has no /opt/resource/out"
