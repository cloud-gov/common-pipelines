#!/bin/bash
# Common helpers shared by every concourse-tests script and helper library.
#
# This file centralizes the boilerplate that used to be copy-pasted into each
# per-image script and duplicated across resource-helpers.sh and
# service-helpers.sh:
#   - resolving the scratch workspace ($CONCOURSE_WORKSPACE, with a temp-dir
#     fallback for standalone runs)
#   - asserting that commands exist on PATH
#
# Per-image scripts source this file via ct_bootstrap (see below), which also
# prints the standard "Testing <name> in Concourse context" banner.

# Prepare and cd into the scratch workspace. Uses $CONCOURSE_WORKSPACE provided
# by integration-test.sh, falling back to a fresh temp dir for standalone runs.
setup_workspace() {
  : "${CONCOURSE_WORKSPACE:=$(mktemp -d)}"
  mkdir -p "$CONCOURSE_WORKSPACE"
  cd "$CONCOURSE_WORKSPACE" || return 1
}

# Verify one or more commands are available on PATH; fail if any is missing.
# Usage: assert_commands git jq aws
assert_commands() {
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

# Bootstrap a per-image test script: print the standard banner, source the
# requested helper library (resource | service | runtime), and prepare the
# scratch workspace. Resolves lib/ relative to the calling script.
#
# Usage (from an image script): ct_bootstrap <image-name> <resource|service|runtime>
ct_bootstrap() {
  local name="$1" kind="$2"
  echo "  → Testing ${name} in Concourse context"
  local lib_dir
  lib_dir="$(cd "$(dirname "${BASH_SOURCE[1]}")/lib" && pwd)"
  case "$kind" in
    resource) . "$lib_dir/resource-helpers.sh" ;;
    service)  . "$lib_dir/service-helpers.sh" ;;
    runtime)  . "$lib_dir/runtime-helpers.sh" ;;
    *) echo "  ✗ ct_bootstrap: unknown helper kind '$kind'"; return 1 ;;
  esac
  setup_workspace
}
