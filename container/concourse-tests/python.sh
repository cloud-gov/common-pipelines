#!/bin/bash
set -e

echo "  → Testing Python image in Concourse context"

cd /tmp/build/workspace

# Test 1: Python and pip versions
echo "  → Testing Python and pip"
python3 --version >/dev/null && echo "  ✓ Python available ($(python3 --version))"
pip3 --version >/dev/null && echo "  ✓ pip available"

# Test 2: pip install
echo "  → Testing pip install"
mkdir -p src/app
cd src/app
cat > requirements.txt <<EOF
requests==2.31.0
EOF

pip3 install --quiet -r requirements.txt && echo "  ✓ pip install works"

# Test 3: Python execution
echo "  → Testing Python execution"
python3 -c "import requests; print('Module loading works')" >/dev/null 2>&1 && \
  echo "  ✓ Python can import installed modules"

# Test 4: Virtual environment (common pattern)
echo "  → Testing virtual environment"
cd /tmp/build/workspace/src
python3 -m venv test-venv >/dev/null 2>&1
. test-venv/bin/activate
pip install --quiet requests >/dev/null 2>&1
python -c "import requests" >/dev/null 2>&1 && echo "  ✓ Virtual environment works"
deactivate

# Test 5: Output artifacts
mkdir -p /tmp/build/workspace/output
echo "build-complete" > /tmp/build/workspace/output/result.txt
[ -f /tmp/build/workspace/output/result.txt ] && echo "  ✓ Output artifacts work"

echo "  ✓ Python image Concourse validation passed"
