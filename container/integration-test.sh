#!/bin/bash
set -e

# Integration Test Script
# Runs standard integration tests and optional Concourse context validation

# Resolve this script's directory so paths are independent of the current
# working directory (do NOT rely on cd-ing into the workspace).
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== Integration Test: Starting ==="
echo "Image: ${IMAGE_REPOSITORY}:staging"
echo ""

# ============================================
# Standard Integration Test
# ============================================
echo "→ Running standard integration test"
$INTEGRATION_TEST_CMD $INTEGRATION_TEST_ARGS
echo "✓ Standard integration test passed"
echo ""

# ============================================
# Concourse Context Validation
# ============================================
if [ "$ENABLE_CONCOURSE_VALIDATION" = "true" ]; then
  echo "=== Concourse Context Validation: Starting ==="
  echo ""

  # When Concourse runs this task it places each declared input/output in its
  # own directory under the task working directory (see integration-test.yml:
  # inputs common-pipelines, src). We validate from that real working directory
  # rather than fabricating a /tmp/build/workspace tree.
  CONCOURSE_WORKDIR="$(pwd)"
  echo "→ Concourse task working directory"
  echo "  ℹ $CONCOURSE_WORKDIR"
  for input in common-pipelines src; do
    if [ -d "$CONCOURSE_WORKDIR/$input" ]; then
      echo "  ✓ Input '$input' present (mounted by Concourse)"
    fi
  done
  echo ""

  # Provide a writable scratch workspace for the per-image tests. Child scripts
  # use $CONCOURSE_WORKSPACE; we create a real temp dir and clean it up on exit.
  echo "→ Setting up scratch workspace"
  CONCOURSE_WORKSPACE="$(mktemp -d)"
  export CONCOURSE_WORKSPACE
  mkdir -p "$CONCOURSE_WORKSPACE"/{src,output}
  trap 'rm -rf "$CONCOURSE_WORKSPACE"' EXIT
  echo "  ✓ Scratch workspace: $CONCOURSE_WORKSPACE"
  echo ""

  # Report the image's default user context.
  # Concourse runs a task as the image's default USER unless the task sets
  # run.user or privileged. It does NOT force non-root; many of these images
  # run as root by default.
  echo "→ Checking user context"
  echo "  ℹ Image default user: UID $(id -u) ($(id -un 2>/dev/null || echo unknown))"
  if [ "$(id -u)" = "0" ]; then
    echo "  ℹ Running as root — Concourse will run this image as root unless the"
    echo "    task sets run.user. This is common for these images."
  else
    echo "  ℹ Running as non-root (UID $(id -u)) — set via the image Dockerfile USER."
  fi
  echo ""

  # Verify the scratch workspace is writable (inputs/outputs are writable in
  # Concourse task containers).
  echo "→ Testing filesystem operations"
  touch "$CONCOURSE_WORKSPACE/src/test-write.txt" && rm "$CONCOURSE_WORKSPACE/src/test-write.txt" && \
    echo "  ✓ Can write to src directory"
  touch "$CONCOURSE_WORKSPACE/output/test-output.txt" && \
    echo "  ✓ Can write to output directory"
  echo ""
  
  # Run image-specific Concourse tests
  CONCOURSE_TEST_SCRIPT="$SCRIPT_DIR/concourse-tests/${IMAGE_REPOSITORY}.sh"
  if [ -f "$CONCOURSE_TEST_SCRIPT" ]; then
    echo "→ Running Concourse-specific tests for '${IMAGE_REPOSITORY}'"
    chmod +x "$CONCOURSE_TEST_SCRIPT"
    "$CONCOURSE_TEST_SCRIPT"
    echo "  ✓ Image-specific Concourse tests passed"
  else
    echo "→ No Concourse-specific tests found for '${IMAGE_REPOSITORY}'"
    echo "  Expected: $CONCOURSE_TEST_SCRIPT"
    echo "  ℹ This is OK - image will use generic validation only"
  fi
  echo ""
  
  echo "=== Concourse Context Validation: PASSED ==="
  echo ""
else
  echo "ℹ Concourse context validation disabled (ENABLE_CONCOURSE_VALIDATION=false)"
  echo "  To enable: Set 'enable-concourse-validation: \"true\"' in vars.yml"
  echo ""
fi

echo "=== Integration Test: PASSED ==="
