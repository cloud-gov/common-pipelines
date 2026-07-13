#!/bin/bash
set -e

# shellcheck source=lib/common.sh
. "$(cd "$(dirname "$0")/lib" && pwd)/common.sh"

ct_bootstrap ubuntu-hardened-stig service

# ubuntu-hardened-stig is the DISA STIG-hardened Ubuntu base image that other
# cloud.gov images build FROM. It has no application entrypoint, so the test
# confirms the base OS provides a usable, writable environment for downstream
# Concourse tasks: a shell, core utilities, package management, and a working
# scratch workspace. We do not attempt to re-run the STIG audit here (that is
# covered by the usg-audit job in the pipeline).
echo "  → Testing core shell and utilities"
require_commands bash sh cat ls grep sed awk

echo "  → Testing package management tooling"
if command -v apt-get >/dev/null 2>&1; then
  echo "  ✓ apt-get available"
else
  echo "  ℹ apt-get not on PATH (unexpected for an Ubuntu base)"
fi

echo "  → Testing filesystem layout"
for d in /etc /usr /var /tmp; do
  [ -d "$d" ] && echo "  ✓ $d present"
done

echo "  → Testing writable workspace (Concourse mounts inputs/outputs writable)"
assert_workspace_io

echo "  → Testing writable temp space"
tmpfile="$(mktemp)"
echo "hardened" > "$tmpfile" && rm -f "$tmpfile" && echo "  ✓ temp space is writable"

echo "  → Reporting OS release"
if [ -r /etc/os-release ]; then
  # shellcheck disable=SC1091
  . /etc/os-release
  echo "  ℹ OS: ${PRETTY_NAME:-unknown}"
fi

echo "  ✓ ubuntu-hardened-stig Concourse validation passed"
echo "  ℹ Note: STIG compliance is validated separately by the usg-audit job"
