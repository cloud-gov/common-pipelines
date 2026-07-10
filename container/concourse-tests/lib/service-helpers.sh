#!/bin/bash
# Shared helpers for Concourse service/task image smoke tests.
#
# These images are not Concourse resources; they provide binaries, runtimes,
# or long-running services. Per the concourse-tests README we only run fast,
# offline smoke checks: verify binaries exist and report a version, validate
# config syntax where cheap, and confirm workspace filesystem operations. We
# do NOT start daemons, open ports, or make network calls.
#
# Shared workspace/command helpers (setup_workspace, assert_commands,
# report_commands) live in common.sh, sourced here so service scripts get
# everything from one source.

# shellcheck source=common.sh
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

# Backwards-compatible aliases for the shared helpers.
service_setup_workspace() { setup_workspace; }
require_commands() { assert_commands "$@"; }

# Assert a file exists (executable/binary or config) at an absolute path.
# Usage: assert_path /app/csb
assert_path() {
  local path="$1"
  if [ -e "$path" ]; then
    echo "  ✓ $path present"
    return 0
  fi
  echo "  ✗ $path not found"
  return 1
}

# Verify the scratch workspace supports the src/output pattern used by tasks.
assert_workspace_io() {
  mkdir -p src output
  echo "test" > src/file.txt
  cp src/file.txt output/result.txt
  [ -f output/result.txt ] && echo "  ✓ workspace src/output operations work"
}
