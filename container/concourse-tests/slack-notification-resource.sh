#!/bin/bash
set -e

# shellcheck source=lib/common.sh
. "$(cd "$(dirname "$0")/lib" && pwd)/common.sh"

ct_bootstrap slack-notification-resource resource

# slack-notification-resource is an out-only notification resource: check/in are
# frequently not implemented, so we guard those and only require the out
# protocol. The shared helpers validate protocol compliance and tolerate the
# expected non-zero exit without a real webhook (see lib/resource-helpers.sh).

# check is optional for this resource.
if [ -x /opt/resource/check ]; then
  check_protocol '{"source":{"url":"https://hooks.slack.com/services/fake/webhook"},"version":null}'
else
  echo "  ℹ check not implemented (expected for notification resource)"
fi

# in is optional for this resource.
if [ -x /opt/resource/in ]; then
  in_protocol '{"source":{"url":"https://hooks.slack.com/services/fake/webhook"},"version":null}'
else
  echo "  ℹ in not implemented (may be acceptable for notification resource)"
fi

# out is the main functionality and must be present.
out_protocol '{"source":{"url":"https://hooks.slack.com/services/fake/webhook"},"params":{"text":"Test notification"}}'

# Test: curl available (needed for webhook calls)
echo "  → Testing curl availability"
curl --version >/dev/null 2>&1 && echo "  ✓ curl available"

echo "  ✓ slack-notification-resource Concourse protocol validation passed"
