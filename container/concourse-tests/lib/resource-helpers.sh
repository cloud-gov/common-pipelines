#!/bin/bash
# Shared helpers for Concourse resource protocol validation.
#
# These functions test the Concourse resource contract
# (https://concourse-ci.org/implementing-resource-types.html):
#   /opt/resource/check  reads JSON on stdin, writes a JSON array on stdout
#   /opt/resource/in      reads JSON on stdin, writes a JSON object on stdout
#   /opt/resource/out     reads JSON on stdin, writes a JSON object on stdout
#
# Resource scripts often exit non-zero without valid credentials/network.
# That is expected here: we only assert the scripts EXIST, are executable,
# and (when they emit output) emit protocol-compliant JSON. We never make
# real network calls or supply real credentials.
#
# Shared workspace/command helpers (setup_workspace, assert_commands) live in
# common.sh, sourced here so resource scripts get everything from one source.

# shellcheck source=common.sh
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

# Backwards-compatible alias: older scripts call resource_setup_workspace.
resource_setup_workspace() { setup_workspace; }

# Assert an /opt/resource/<name> script exists and is executable.
# Usage: assert_resource_script check
assert_resource_script() {
  local name="$1"
  local path="/opt/resource/$name"
  if [ -x "$path" ]; then
    echo "  ✓ $path present and executable"
    return 0
  fi
  echo "  ✗ $path missing or not executable"
  return 1
}

# Run /opt/resource/check with the given JSON payload and validate that any
# output is a JSON array (success) or a JSON object (error report). A non-zero
# exit without credentials is tolerated.
# Usage: check_protocol <payload-json>
check_protocol() {
  local payload="$1"
  assert_resource_script check || return 1
  printf '%s' "$payload" > check-input.json
  /opt/resource/check < check-input.json > check-output.json 2>/dev/null || \
    echo "  ℹ check exited non-zero (expected without credentials/network)"
  if [ -s check-output.json ]; then
    if jq -e 'type == "array" or (type == "object" and has("error"))' \
        check-output.json >/dev/null 2>&1; then
      echo "  ✓ check emits protocol-compliant JSON"
    else
      echo "  ✗ check output is not a JSON array/error object"
      return 1
    fi
  else
    echo "  ℹ check produced no output (acceptable on credential failure)"
  fi
}

# Run /opt/resource/in <dest> with the given JSON payload and validate that any
# output is a JSON object.
# Usage: in_protocol <payload-json>
in_protocol() {
  local payload="$1"
  assert_resource_script in || return 1
  mkdir -p dest
  printf '%s' "$payload" > in-input.json
  /opt/resource/in dest < in-input.json > in-output.json 2>/dev/null || \
    echo "  ℹ in exited non-zero (expected without credentials/network)"
  if [ -s in-output.json ]; then
    if jq -e 'type == "object"' in-output.json >/dev/null 2>&1; then
      echo "  ✓ in emits a JSON object"
    else
      echo "  ✗ in output is not a JSON object"
      return 1
    fi
  else
    echo "  ℹ in produced no output (acceptable on credential failure)"
  fi
}

# Run /opt/resource/out <src> with the given JSON payload and validate that any
# output is a JSON object.
# Usage: out_protocol <payload-json>
out_protocol() {
  local payload="$1"
  assert_resource_script out || return 1
  mkdir -p src
  printf '%s' "$payload" > out-input.json
  /opt/resource/out src < out-input.json > out-output.json 2>/dev/null || \
    echo "  ℹ out exited non-zero (expected without credentials/network)"
  if [ -s out-output.json ]; then
    if jq -e 'type == "object"' out-output.json >/dev/null 2>&1; then
      echo "  ✓ out emits a JSON object"
    else
      echo "  ✗ out output is not a JSON object"
      return 1
    fi
  else
    echo "  ℹ out produced no output (acceptable on credential failure)"
  fi
}
