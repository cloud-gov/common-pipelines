#!/bin/bash
set -e

# shellcheck source=lib/common.sh
. "$(cd "$(dirname "$0")/lib" && pwd)/common.sh"

ct_bootstrap semver-resource resource

# semver-resource here uses the git driver; ensure git never blocks on a
# credential prompt.
git_noninteractive

# semver-resource manages a semantic version stored in a backing driver
# (git/s3/etc). Without a reachable backend the scripts fail; we validate
# protocol compliance.
check_protocol '{"source":{"driver":"git","uri":"https://github.com/cloud-gov/example.git","branch":"version","file":"version"},"version":null}'
in_protocol    '{"source":{"driver":"git","uri":"https://github.com/cloud-gov/example.git","branch":"version","file":"version"},"version":{"number":"1.0.0"}}'
out_protocol   '{"source":{"driver":"git","uri":"https://github.com/cloud-gov/example.git","branch":"version","file":"version"},"params":{"bump":"patch"}}'

echo "  ✓ semver-resource Concourse protocol validation passed"
