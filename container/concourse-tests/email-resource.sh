#!/bin/bash
set -e

echo "  → Testing email-resource in Concourse context"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/resource-helpers.sh
. "$SCRIPT_DIR/lib/resource-helpers.sh"

resource_setup_workspace

# email-resource is an output-only notification resource. check and in are
# stubs (check returns a static version). out sends email via SMTP; without a
# reachable SMTP server it exits non-zero. We validate protocol compliance for
# whatever endpoints are implemented.
if [ -x /opt/resource/check ]; then
  check_protocol '{"source":{},"version":null}'
else
  echo "  ℹ check not implemented (acceptable for notification resource)"
fi

cat > out-params.yml <<'EOF'
smtp:
  host: smtp.example.com
  port: "25"
EOF

out_protocol '{"source":{"smtp":{"host":"smtp.example.com","port":"25","anonymous":true}},"params":{"subject":"src/subject.txt","body":"src/body.txt"}}'

echo "  ✓ email-resource Concourse protocol validation passed"
