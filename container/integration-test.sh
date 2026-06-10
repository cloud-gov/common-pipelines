#!/bin/bash
set -e

# Integration Test Script
# Runs standard integration tests and optional Concourse context validation

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
  
  # Create Concourse-like workspace structure
  echo "→ Setting up Concourse-like workspace"
  mkdir -p /tmp/build/workspace/{src,output,artifacts}
  cd /tmp/build/workspace
  echo "  ✓ Workspace structure created"
  echo ""
  
  # Test running as non-root (Concourse behavior)
  echo "→ Checking user context"
  if [ "$(id -u)" = "0" ]; then
    echo "  ⚠ Running as root (UID 0)"
    echo "  Note: Concourse typically runs tasks as non-root"
  else
    echo "  ✓ Running as non-root user (UID $(id -u))"
  fi
  echo ""
  
  # Test filesystem operations (volume mounts)
  echo "→ Testing filesystem operations"
  touch src/test-write.txt && rm src/test-write.txt && \
    echo "  ✓ Can write to src directory (input mount simulation)"
  touch output/test-output.txt && \
    echo "  ✓ Can write to output directory (output mount simulation)"
  echo ""
  
  # Run image-specific Concourse tests
  CONCOURSE_TEST_SCRIPT="common-pipelines/container/concourse-tests/${IMAGE_TYPE}.sh"
  if [ -f "$CONCOURSE_TEST_SCRIPT" ]; then
    echo "→ Running Concourse-specific tests for '${IMAGE_TYPE}'"
    chmod +x "$CONCOURSE_TEST_SCRIPT"
    "$CONCOURSE_TEST_SCRIPT"
    echo "  ✓ Image-specific Concourse tests passed"
  else
    echo "→ No Concourse-specific tests found for '${IMAGE_TYPE}'"
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
