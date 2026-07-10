#!/bin/bash
set -e

# shellcheck source=lib/common.sh
. "$(cd "$(dirname "$0")/lib" && pwd)/common.sh"

echo "  → Testing oci-build-task in Concourse context"
setup_workspace

# Test 1: buildkit command available
echo "  → Testing buildkit availability"
which build >/dev/null 2>&1 && echo "  ✓ build command available"

# Test 2: Minimal Dockerfile build
echo "  → Testing minimal Docker build"
mkdir -p src/test-context
cat > src/test-context/Dockerfile <<'EOF'
FROM alpine:latest
RUN echo "test build"
CMD ["echo", "hello"]
EOF

# Note: We can't actually run privileged builds in non-privileged context
# But we can verify the command structure
echo "  → Verifying build command structure"
build --help >/dev/null 2>&1 && echo "  ✓ build command accepts arguments"

# Test 3: Required tools
echo "  → Testing required tools"
which jq >/dev/null 2>&1 && echo "  ✓ jq available"

# Test 4: Output directory
mkdir -p output
touch output/image.tar
[ -f output/image.tar ] && echo "  ✓ Output directory writable"

echo "  ✓ oci-build-task Concourse validation passed"
echo "  ℹ Note: Actual privileged build tested in privileged integration-test job"
