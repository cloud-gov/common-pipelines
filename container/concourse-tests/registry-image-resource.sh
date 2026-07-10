#!/bin/bash
set -e

# shellcheck source=lib/common.sh
. "$(cd "$(dirname "$0")/lib" && pwd)/common.sh"

ct_bootstrap registry-image-resource resource

# registry-image-resource pulls/pushes OCI images from a registry. Without a
# reachable registry the scripts fail; we validate protocol compliance.
check_protocol '{"source":{"repository":"library/alpine","tag":"latest"},"version":null}'
in_protocol    '{"source":{"repository":"library/alpine","tag":"latest"},"version":{"digest":"sha256:0000000000000000000000000000000000000000000000000000000000000000"}}'
out_protocol   '{"source":{"repository":"library/alpine","tag":"latest"},"params":{"image":"src/image.tar"}}'

echo "  ✓ registry-image-resource Concourse protocol validation passed"
