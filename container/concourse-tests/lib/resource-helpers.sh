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

# Validate that a file contains protocol-shaped JSON.
#
# Some hardened resource images run the upstream resource binary on a base image
# that does not ship jq (e.g. bosh-io-stemcell-resource, which builds the
# upstream Dockerfile on ubuntu-hardened). Without a jq guard the "$( ) && jq"
# chain fails whenever jq is missing, producing a FALSE protocol violation even
# when stdout was valid JSON. This helper uses jq for a strict check when it is
# available, and falls back to a dependency-free structural check otherwise.
#
# Per the Concourse resource contract, check emits a top-level JSON array on
# success (some resources emit a JSON error object instead), while in/out emit
# a top-level JSON object. Inspecting the first non-whitespace byte is therefore
# sufficient to catch the real failure modes (empty output, a bare scalar, or a
# stderr banner leaking onto stdout) without a full JSON parser.
#
# Usage: json_is <array|object> <file>
json_is() {
  local want="$1" file="$2"
  if command -v jq >/dev/null 2>&1; then
    case "$want" in
      array)  jq -e 'type == "array" or (type == "object" and has("error"))' "$file" >/dev/null 2>&1 ;;
      object) jq -e 'type == "object"' "$file" >/dev/null 2>&1 ;;
      *) return 1 ;;
    esac
    return
  fi

  # jq-less fallback: inspect the first non-whitespace byte of the file.
  local first
  first=$(tr -d '[:space:]' < "$file" | cut -c1)
  case "$want" in
    array)
      # A JSON array starts with '['. Tolerate a JSON error object as well
      # ('{' with an "error" key), matching the jq expression above.
      [ "$first" = "[" ] && return 0
      { [ "$first" = "{" ] && grep -q '"error"' "$file"; } && return 0
      return 1 ;;
    object)
      [ "$first" = "{" ] ;;
    *)
      return 1 ;;
  esac
}

# Emit a one-time informational note when jq is unavailable so the verification
# transcript is honest about the reduced-strictness (structural) JSON check.
# The guard variable is set on first call to avoid repeating the note for every
# check/in/out assertion in a single script run.
_json_note_if_no_jq() {
  if ! command -v jq >/dev/null 2>&1 && [ -z "${_JSON_NO_JQ_NOTED:-}" ]; then
    echo "  ℹ jq not found; using dependency-free JSON shape check"
    _JSON_NO_JQ_NOTED=1
  fi
}

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
  _json_note_if_no_jq

  if [ "$rc" -eq 0 ]; then
    # Success: stdout must be protocol-compliant JSON.
    if [ -s check-output.json ] && json_is array check-output.json; then
      echo "  ✓ check emits protocol-compliant JSON"
    else
      echo "  ✗ check exited 0 but stdout is not a JSON array/error object"
      return 1
    fi
  else
    # Non-zero exit is expected without credentials/network. stdout is advisory.
    echo "  ℹ check exited non-zero (expected without credentials/network)"
    if [ -s check-output.json ]; then
      if json_is array check-output.json; then
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
  _json_note_if_no_jq

  if [ "$rc" -eq 0 ]; then
    if [ -s in-output.json ] && json_is object in-output.json; then
      echo "  ✓ in emits a JSON object"
    else
      echo "  ✗ in exited 0 but stdout is not a JSON object"
      return 1
    fi
  else
    echo "  ℹ in exited non-zero (expected without credentials/network)"
    if [ -s in-output.json ] && json_is object in-output.json; then
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
  _json_note_if_no_jq

  if [ "$rc" -eq 0 ]; then
    if [ -s out-output.json ] && json_is object out-output.json; then
      echo "  ✓ out emits a JSON object"
    else
      echo "  ✗ out exited 0 but stdout is not a JSON object"
      return 1
    fi
  else
    echo "  ℹ out exited non-zero (expected without credentials/network)"
    if [ -s out-output.json ] && json_is object out-output.json; then
      echo "  ✓ out still emitted a JSON object on failure"
    else
      echo "  ℹ out produced no protocol JSON on stdout (diagnostics go to stderr; acceptable)"
    fi
  fi
}
