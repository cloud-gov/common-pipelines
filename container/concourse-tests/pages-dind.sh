#!/bin/bash
set -e

echo "  → Testing pages-dind in Concourse context"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/service-helpers.sh
. "$SCRIPT_DIR/lib/service-helpers.sh"

service_setup_workspace

# pages-dind provides Docker-in-Docker (docker CLI + dockerd + buildx +
# compose). Starting dockerd requires privileged mode and is exercised in the
# privileged build/integration steps, not here. Verify the client tooling is
# present and reports versions (client version does not need a daemon).
echo "  → Testing docker CLI"
require_commands docker

echo "  ✓ docker client: $(docker --version 2>&1)"

echo "  → Testing dockerd presence"
if command -v dockerd >/dev/null 2>&1; then
  echo "  ✓ dockerd available ($(dockerd --version 2>&1))"
else
  echo "  ✗ dockerd not found"
  exit 1
fi

echo "  → Testing buildx / compose plugins"
docker buildx version >/dev/null 2>&1 && echo "  ✓ docker buildx available" || \
  echo "  ℹ docker buildx not reporting version"
docker compose version >/dev/null 2>&1 && echo "  ✓ docker compose available" || \
  echo "  ℹ docker compose not reporting version"

assert_workspace_io

echo "  ✓ pages-dind Concourse validation passed"
echo "  ℹ Note: dockerd daemon requires privileged mode; not started here"
