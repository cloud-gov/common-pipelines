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

# Force git into non-interactive, fail-fast mode for git-backed resource tests.
#
# Without valid credentials/network, git's credential subsystem falls back to an
# interactive "Username for 'https://...':" prompt. In a Concourse task a
# terminal is attached, so git blocks on that prompt forever and the test never
# completes. These exported settings make git fail fast instead of prompting:
#   GIT_TERMINAL_PROMPT=0  disables the username/password terminal prompt
#   GIT_ASKPASS=true       makes any askpass invocation return empty immediately
#   GCM_INTERACTIVE=never  disables the Git Credential Manager prompt (if present)
#   credential.helper=""   clears any inherited helper that might prompt
# Exported so they are inherited by git invoked inside /opt/resource/{check,in,out}.
# Call this near the top of any git-backed resource test (git, pool, rwlock,
# semver with driver=git, etc.).
git_noninteractive() {
  export GIT_TERMINAL_PROMPT=0
  export GIT_ASKPASS=true
  export GCM_INTERACTIVE=never
  export GIT_CONFIG_COUNT=1
  export GIT_CONFIG_KEY_0=credential.helper
  export GIT_CONFIG_VALUE_0=
  echo "  ℹ git configured for non-interactive mode (no credential prompts)"
}

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

# Run /opt/resource/check with the given JSON payload and validate protocol
# compliance. Per the Concourse resource contract, check writes a JSON array to
# stdout ONLY on success; failure is signaled by a non-zero exit code with
# diagnostics on stderr (stdout is not required to be JSON in that case).
#
# We therefore gate stdout validation on the exit code:
#   - exit 0  -> stdout MUST be a JSON array (or a JSON error object, which some
#                resources emit); anything else is a protocol violation.
#   - exit !0 -> expected here (no credentials/network). Any stdout is advisory
#                only: we report whether it happens to be protocol-shaped, but a
#                non-JSON diagnostic on stdout is NOT a failure.
# Usage: check_protocol <payload-json>
check_protocol() {
  local payload="$1"
  assert_resource_script check || return 1
  printf '%s' "$payload" > check-input.json
  local rc=0
  /opt/resource/check < check-input.json > check-output.json 2>/dev/null || rc=$?

  if [ "$rc" -eq 0 ]; then
    # Success: stdout must be protocol-compliant JSON.
    if [ -s check-output.json ] && jq -e \
        'type == "array" or (type == "object" and has("error"))' \
        check-output.json >/dev/null 2>&1; then
      echo "  ✓ check emits protocol-compliant JSON"
    else
      echo "  ✗ check exited 0 but stdout is not a JSON array/error object"
      return 1
    fi
  else
    # Non-zero exit is expected without credentials/network. stdout is advisory.
    echo "  ℹ check exited non-zero (expected without credentials/network)"
    if [ -s check-output.json ]; then
      if jq -e 'type == "array" or (type == "object" and has("error"))' \
          check-output.json >/dev/null 2>&1; then
        echo "  ✓ check still emitted protocol-compliant JSON on failure"
      else
        echo "  ℹ check wrote non-JSON diagnostics to stdout on failure (tolerated)"
      fi
    else
      echo "  ℹ check produced no stdout (diagnostics go to stderr; acceptable)"
    fi
  fi
}

# Run /opt/resource/in <dest> with the given JSON payload and validate protocol
# compliance. On success (exit 0) stdout MUST be a JSON object; on the expected
# non-zero exit (no credentials/network) stdout is advisory only.
# Usage: in_protocol <payload-json>
in_protocol() {
  local payload="$1"
  assert_resource_script in || return 1
  mkdir -p dest
  printf '%s' "$payload" > in-input.json
  local rc=0
  /opt/resource/in dest < in-input.json > in-output.json 2>/dev/null || rc=$?

  if [ "$rc" -eq 0 ]; then
    if [ -s in-output.json ] && jq -e 'type == "object"' in-output.json >/dev/null 2>&1; then
      echo "  ✓ in emits a JSON object"
    else
      echo "  ✗ in exited 0 but stdout is not a JSON object"
      return 1
    fi
  else
    echo "  ℹ in exited non-zero (expected without credentials/network)"
    if [ -s in-output.json ] && jq -e 'type == "object"' in-output.json >/dev/null 2>&1; then
      echo "  ✓ in still emitted a JSON object on failure"
    else
      echo "  ℹ in produced no protocol JSON on stdout (diagnostics go to stderr; acceptable)"
    fi
  fi
}

# Run /opt/resource/out <src> with the given JSON payload and validate protocol
# compliance. On success (exit 0) stdout MUST be a JSON object; on the expected
# non-zero exit (no credentials/network) stdout is advisory only.
# Usage: out_protocol <payload-json>
out_protocol() {
  local payload="$1"
  assert_resource_script out || return 1
  mkdir -p src
  printf '%s' "$payload" > out-input.json
  local rc=0
  /opt/resource/out src < out-input.json > out-output.json 2>/dev/null || rc=$?

  if [ "$rc" -eq 0 ]; then
    if [ -s out-output.json ] && jq -e 'type == "object"' out-output.json >/dev/null 2>&1; then
      echo "  ✓ out emits a JSON object"
    else
      echo "  ✗ out exited 0 but stdout is not a JSON object"
      return 1
    fi
  else
    echo "  ℹ out exited non-zero (expected without credentials/network)"
    if [ -s out-output.json ] && jq -e 'type == "object"' out-output.json >/dev/null 2>&1; then
      echo "  ✓ out still emitted a JSON object on failure"
    else
      echo "  ℹ out produced no protocol JSON on stdout (diagnostics go to stderr; acceptable)"
    fi
  fi
}
