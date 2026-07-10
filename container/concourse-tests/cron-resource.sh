#!/bin/bash
set -e

# shellcheck source=lib/common.sh
. "$(cd "$(dirname "$0")/lib" && pwd)/common.sh"

ct_bootstrap cron-resource resource

# cron-resource triggers on a cron expression. It implements check and in only
# (there is no out). check evaluates the schedule locally, so it should succeed
# and return a JSON array.
check_protocol '{"source":{"expression":"* * * * *","location":"America/New_York"},"version":null}'
in_protocol    '{"source":{"expression":"* * * * *","location":"America/New_York"},"version":{"time":"2020-01-01T00:00:00Z"}}'

echo "  ✓ cron-resource Concourse protocol validation passed"
echo "  ℹ Note: cron-resource intentionally has no /opt/resource/out"
