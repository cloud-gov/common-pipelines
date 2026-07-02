#!/bin/bash
# Shared helpers for Concourse service/task image smoke tests.
#
# These images are not Concourse resources; they provide binaries, runtimes,
# or long-running services. Per the concourse-tests README we only run fast,
# offline smoke checks: verify binaries exist and report a version, validate
# config syntax where cheap, and confirm workspace filesystem operations. We
# do NOT start daemons, open ports, or make network calls.

# Prepare the scratch workspace. Uses $CONCOURSE_WORKSPACE from
# integration-test.sh, falling back to a temp dir for standalone runs.
service_setup_workspace() {
  : "${CONCOURSE_WORKSPACE:=$(mktemp -d)}"
  mkdir -p "$CONCOURSE_WORKSPACE"
  cd "$CONCOURSE_WORKSPACE"
}

# Verify one or more commands are available on PATH; fail if any is missing.
# Usage: require_commands bash apt-get
require_commands() {
  local cmd
  for cmd in "$@"; do
    if command -v "$cmd" >/dev/null 2>&1; then
      echo "  ✓ $cmd available"
    else
      echo "  ✗ $cmd not found"
      return 1
    fi
  done
}

# Report the presence of optional commands without failing.
# Usage: report_commands ruby python3
report_commands() {
  local cmd
  for cmd in "$@"; do
    if command -v "$cmd" >/dev/null 2>&1; then
      echo "  ✓ $cmd available"
    else
      echo "  ℹ $cmd not present (optional)"
    fi
  done
}

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
