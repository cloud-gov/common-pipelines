#!/bin/bash
set -e

echo "  → Testing general-task in Concourse context"

cd /tmp/build/workspace

# Test 1: Critical CLI tools
echo "  → Testing critical CLI tools"
for tool in git cf bosh terraform jq yq; do
  if which "$tool" >/dev/null 2>&1; then
    VERSION=$($tool --version 2>&1 | head -1 || echo "present")
    echo "  ✓ $tool available"
  else
    echo "  ✗ $tool not found"
    exit 1
  fi
done

# Test 2: Git operations (most common Concourse task)
echo "  → Testing git operations"
git config --global user.email "test@example.com"
git config --global user.name "Test User"
mkdir -p src/repo
cd src/repo
git init >/dev/null 2>&1
echo "test" > README.md
git add README.md
git commit -m "test commit" >/dev/null 2>&1
echo "  ✓ git operations work"

# Test 3: CF CLI
echo "  → Testing CF CLI"
cf api --version >/dev/null 2>&1 && echo "  ✓ CF CLI works"

# Test 4: Terraform
echo "  → Testing Terraform"
cd /tmp/build/workspace
cat > src/test.tf <<EOF
variable "test" {
  default = "value"
}
EOF
terraform -chdir=src init >/dev/null 2>&1 && echo "  ✓ Terraform init works"
terraform -chdir=src validate >/dev/null 2>&1 && echo "  ✓ Terraform validate works"

# Test 5: Output artifacts (common pattern)
echo "  → Testing output artifacts"
mkdir -p output
echo "deployment-complete" > output/status.txt
[ -f output/status.txt ] && echo "  ✓ Output artifact creation works"

# Test 6: Ruby (if present)
if which ruby >/dev/null 2>&1; then
  ruby --version >/dev/null 2>&1 && echo "  ✓ Ruby available"
fi

# Test 7: Python (if present)
if which python3 >/dev/null 2>&1; then
  python3 --version >/dev/null 2>&1 && echo "  ✓ Python available"
fi

echo "  ✓ general-task Concourse validation passed"
