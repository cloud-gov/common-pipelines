# Concourse Context Validation Tests

This directory contains validation scripts that test images in Concourse-like execution contexts.

## Purpose

These tests simulate how Concourse runs containers:
- The real task working directory, where Concourse mounts each declared
  input/output in its own subdirectory
- A writable scratch workspace exposed via the `$CONCOURSE_WORKSPACE`
  environment variable (set by `integration-test.sh`)
- Resource protocol compliance (stdin/stdout JSON for resources)
- Typical task operations (git clone, builds, deployments)

## Workspace Convention

`integration-test.sh` creates a real temporary directory (via `mktemp -d`),
exports it as `CONCOURSE_WORKSPACE`, and cleans it up on exit. Each test
script MUST use `$CONCOURSE_WORKSPACE` rather than hardcoding a path. For
standalone runs, scripts fall back to their own `mktemp -d` if the variable is
unset:

```bash
: "${CONCOURSE_WORKSPACE:=$(mktemp -d)}"
mkdir -p "$CONCOURSE_WORKSPACE"
cd "$CONCOURSE_WORKSPACE"
```

## When Tests Run

Concourse validation runs during the **integration-test job** when:
1. `enable-concourse-validation: "true"` is set in the pipeline's `vars.yml`
2. The image has passed smoke tests
3. The staging image (`:staging` tag) is being tested

## Test Script Naming

Scripts are named after the `image-repository` parameter:
- `s3-resource.sh` → `image-repository: s3-resource`
- `general-task.sh` → `image-repository: general-task`
- `pages-node-v22.sh` → `image-repository: pages-node-v22`

The `image-repository` is the ECR repository name for the image. For pages
images it is prefixed (e.g. `pages-node-v22`) so each script name is unique
across teams.

## Shared Libraries

Common assertions live in `lib/` and are sourced by the per-image scripts so
logic is written once:

- `lib/resource-helpers.sh` — Concourse resource-protocol assertions
  (`check_protocol`, `in_protocol`, `out_protocol`, `assert_resource_script`,
  `assert_commands`). Used by all `*-resource` images.
- `lib/service-helpers.sh` — offline binary/config smoke-test assertions
  (`require_commands`, `report_commands`, `assert_path`, `assert_workspace_io`).
  Used by service/task images (broker, clamav, postgres, redis, dind, zap, etc.).
- `lib/runtime-helpers.sh` — shared language/web runtime tests
  (`run_node_tests`, `run_python_tests`, `run_nginx_tests`). Node/Python/nginx
  and the pages runtime wrappers delegate here.

Per-image scripts resolve `lib/` relative to their own location:

```bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/lib/resource-helpers.sh"
```

## Image Inventory

Every image built by the base, internal, external, and pages pipelines has a
matching test script and is wired via `image-repository` + `enable-concourse-validation`
in its `ci/container/**/vars.yml`.

| Pipeline | Image repositories (scripts) |
|----------|------------------------------|
| base | `ubuntu-hardened-stig` |
| internal (resources) | `bosh-deployment-resource`, `cf-resource`, `concourse-rwlock-resource`, `cron-resource`, `github-pr-resource`, `github-release-resource`, `s3-resource`, `s3-simple-resource`, `slack-notification-resource` |
| internal (task/service) | `cg-csb`, `csb-helper`, `clamav-rest-candidate`, `external-domain-broker-testing`, `general-task`, `oci-build-task`, `opensearch-testing`, `opensearch-dashboards-testing`, `playwright-python`, `pulledpork`, `zap-runner` |
| external (resources) | `bosh-io-release-resource`, `bosh-io-stemcell-resource`, `cf-cli-resource`, `email-resource`, `git-resource`, `pool-resource`, `registry-image-resource`, `semver-resource`, `time-resource` |
| external (service) | `cloud-service-broker`, `openresty` |
| pages | `pages-dind`, `pages-nginx-v1`, `pages-node-v22`, `pages-node-v24`, `pages-postgres-v15`, `pages-python-v3.11`, `pages-redis-v7.2`, `pages-zap` |

Generic `node.sh`, `python.sh`, and `nginx.sh` remain as reusable entry points
that delegate to `lib/runtime-helpers.sh`.

## Writing a New Test Script

### 1. Create the script

```bash
#!/bin/bash
set -e  # Exit on first error

echo "  → Testing <image-name> in Concourse context"

# Use the scratch workspace provided by integration-test.sh (fall back to a
# temp dir when run standalone).
: "${CONCOURSE_WORKSPACE:=$(mktemp -d)}"
mkdir -p "$CONCOURSE_WORKSPACE"
cd "$CONCOURSE_WORKSPACE"

# Test 1: Resource-specific functionality
# For resources: test check/in/out protocol
# For task images: test typical operations

# Example for resources:
cat > "$CONCOURSE_WORKSPACE/test-input.json" <<EOF
{"source":{},"version":{}}
EOF

/opt/resource/check < "$CONCOURSE_WORKSPACE/test-input.json" | jq -e 'type == "array"'
echo "  ✓ Resource check returns JSON array"

# Example for task images:
git clone https://github.com/cloud-gov/example.git "$CONCOURSE_WORKSPACE/src/repo"
echo "  ✓ Git operations work"

echo "  ✓ <image-name> Concourse validation passed"
```

### 2. Make it executable

```bash
chmod +x container/concourse-tests/<image-repository>.sh
```

### 3. Test locally (optional)

```bash
docker run --rm \
  -v $(pwd):/workspace \
  <image>:staging \
  /workspace/container/concourse-tests/<image-repository>.sh
```

### 4. Enable in pipeline

The test script is looked up by the image's `image-repository`, which every
`vars.yml` already sets. To turn on Concourse validation, add:

```yaml
enable-concourse-validation: "true"
```

## Test Design Guidelines

### DO:
- ✅ Test actual binaries/commands the image provides
- ✅ Test with Concourse-like directory structure
- ✅ Test resource protocol (stdin/stdout JSON)
- ✅ Exit with non-zero code on failure
- ✅ Print clear success/failure messages

### DON'T:
- ❌ Require external credentials (AWS, GitHub tokens)
- ❌ Make actual network calls to production services
- ❌ Assume specific files exist outside the image
- ❌ Run longer than 2 minutes

## Common Patterns

### Pattern 1: Resource Protocol Test
```bash
# Test check/in/out scripts accept JSON and return JSON
echo '{"source":{},"version":{}}' | /opt/resource/check | jq -e 'type == "array"'
```

### Pattern 2: Command Availability Test
```bash
# Verify expected commands exist and work
for cmd in git cf terraform; do
  $cmd --version >/dev/null && echo "  ✓ $cmd available"
done
```

### Pattern 3: Workspace Operations
```bash
# Test file operations in the scratch workspace
cd "$CONCOURSE_WORKSPACE"
mkdir -p src output
echo "test" > src/file.txt
cat src/file.txt > output/result.txt
[ -f output/result.txt ] && echo "  ✓ Workspace operations work"
```

## Troubleshooting

### Test fails locally but passes in pipeline
- Check that you're using the `:staging` tag
- Ensure `$CONCOURSE_WORKSPACE` resolves (scripts fall back to `mktemp -d`)

### Test passes but real Concourse task fails
- Check for external dependencies (network, credentials)
- Verify volume mount behavior matches test assumptions
- Consider adding more comprehensive tests

### Script not found during integration-test
- Verify script name matches `image-repository` parameter
- Ensure script is executable: `chmod +x <script>`
- Check script is committed to repository

## Examples by Image Type

See existing scripts for reference:
- **Resources:** `s3-resource.sh`, `github-pr-resource.sh` (or the shared `lib/resource-helpers.sh` consumers like `git-resource.sh`, `time-resource.sh`)
- **Task images:** `general-task.sh`, `node.sh`
- **Service images (offline smoke):** `openresty.sh`, `pages-postgres-v15.sh`, `pages-redis-v7.2.sh`, `cloud-service-broker.sh`
- **Privileged tasks:** `oci-build-task.sh`, `pages-dind.sh`
- **Base image:** `ubuntu-hardened-stig.sh`
