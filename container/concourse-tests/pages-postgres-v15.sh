#!/bin/bash
set -e

# shellcheck source=lib/common.sh
. "$(cd "$(dirname "$0")/lib" && pwd)/common.sh"

ct_bootstrap pages-postgres-v15 service

# pages-postgres-v15 packages PostgreSQL 15. The server is started at runtime
# with its own data dir and networking; we do not start it. Verify the server
# and client binaries are present and report versions.
echo "  → Testing PostgreSQL binaries"
POSTGRES_BIN=""
for p in postgres /usr/lib/postgresql/15/bin/postgres; do
  if command -v "$p" >/dev/null 2>&1 || [ -x "$p" ]; then POSTGRES_BIN="$p"; break; fi
done
if [ -n "$POSTGRES_BIN" ]; then
  echo "  ✓ postgres server present ($("$POSTGRES_BIN" --version 2>&1))"
else
  echo "  ✗ postgres server binary not found"
  exit 1
fi

for tool in initdb pg_ctl psql; do
  if command -v "$tool" >/dev/null 2>&1 || \
     [ -x "/usr/lib/postgresql/15/bin/$tool" ]; then
    echo "  ✓ $tool present"
  else
    echo "  ℹ $tool not found on PATH (check /usr/lib/postgresql/15/bin)"
  fi
done

assert_workspace_io

echo "  ✓ pages-postgres-v15 Concourse validation passed"
echo "  ℹ Note: postgres server not started in smoke test"
