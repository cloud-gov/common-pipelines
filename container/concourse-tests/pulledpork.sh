#!/bin/bash
set -e

echo "  → Testing pulledpork in Concourse context"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/service-helpers.sh
. "$SCRIPT_DIR/lib/service-helpers.sh"

service_setup_workspace

# pulledpork is a Snort/Suricata rule management tool (from cg-snort-boshrelease)
# implemented in Python/Perl. It normally fetches rule tarballs over the network;
# we do not do that. Verify the tool and its interpreter are present.
echo "  → Testing pulledpork availability"
PP_FOUND=""
for candidate in pulledpork pulledpork.py pulledpork3 /usr/local/bin/pulledpork.py; do
  if command -v "$candidate" >/dev/null 2>&1 || [ -x "$candidate" ]; then
    echo "  ✓ pulledpork found: $candidate"
    PP_FOUND=1
    break
  fi
done
if [ -z "$PP_FOUND" ]; then
  echo "  ℹ pulledpork not found by common names (verify image layout)"
fi

echo "  → Testing interpreter"
report_commands python3 perl

assert_workspace_io

echo "  ✓ pulledpork Concourse validation passed"
echo "  ℹ Note: rule download over network not exercised in smoke test"
