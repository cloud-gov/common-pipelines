# Concourse Context Validation Tests

This directory contains validation scripts that test images in Concourse-like execution contexts.

## Purpose

These tests simulate how Concourse runs containers:
- Workspace directory structures (`/tmp/build/workspace/`)
- Volume mounting behavior (separate input/output directories)
- Resource protocol compliance (stdin/stdout JSON for resources)
- Typical task operations (git clone, builds, deployments)

## When Tests Run

Concourse validation runs during the **integration-test job** when:
1. `enable-concourse-validation: "true"` is set in the pipeline's `vars.yml`
2. The image has passed smoke tests
3. The staging image (`:staging` tag) is being tested

## Test Script Naming

Scripts are named after the `image-type` parameter:
- `s3-resource.sh` → `image-type: s3-resource`
- `general-task.sh` → `image-type: general-task`
- `node.sh` → `image-type: node`

## Writing a New Test Script

### 1. Create the script

```bash
#!/bin/bash
set -e  # Exit on first error

echo "  → Testing <image-name> in Concourse context"

# Test 1: Resource-specific functionality
# For resources: test check/in/out protocol
# For task images: test typical operations

# Example for resources:
cat > /tmp/build/workspace/test-input.json <<EOF
{"source":{},"version":{}}
EOF

/opt/resource/check < /tmp/build/workspace/test-input.json | jq -e 'type == "array"'
echo "  ✓ Resource check returns JSON array"

# Example for task images:
git clone https://github.com/cloud-gov/example.git /tmp/build/workspace/src/repo
echo "  ✓ Git operations work"

echo "  ✓ <image-name> Concourse validation passed"
```

### 2. Make it executable

```bash
chmod +x container/concourse-tests/<image-type>.sh
```

### 3. Test locally (optional)

```bash
docker run --rm \
  -v $(pwd):/workspace \
  -w /tmp/build/workspace \
  <image>:staging \
  /workspace/container/concourse-tests/<image-type>.sh
```

### 4. Enable in pipeline

Update the pipeline's `vars.yml`:

```yaml
image-type: <image-type>
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
# Test file operations in workspace
cd /tmp/build/workspace
echo "test" > src/file.txt
cat src/file.txt > output/result.txt
[ -f output/result.txt ] && echo "  ✓ Workspace operations work"
```

## Troubleshooting

### Test fails locally but passes in pipeline
- Check that you're using the `:staging` tag
- Verify working directory matches pipeline (`/tmp/build/workspace`)

### Test passes but real Concourse task fails
- Check for external dependencies (network, credentials)
- Verify volume mount behavior matches test assumptions
- Consider adding more comprehensive tests

### Script not found during integration-test
- Verify script name matches `image-type` parameter
- Ensure script is executable: `chmod +x <script>`
- Check script is committed to repository

## Examples by Image Type

See existing scripts for reference:
- **Resources:** `s3-resource.sh`, `github-pr-resource.sh`
- **Task images:** `general-task.sh`, `node.sh`
- **Privileged tasks:** `oci-build-task.sh`
