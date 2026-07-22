#!/bin/bash
set -euo pipefail

# Generate the set of tags to apply to a built image.
#
# The registry-image resource's `additional_tags` param reads a single file
# containing a whitespace-separated list of tags. This script assembles that
# file so that every distinct image build is uniquely and traceably tagged:
#
#   1. <config_digest>              - the sha256 hex of the image config digest,
#                                     guaranteed unique for any change to the image
#   2. <short_ref>-<short_digest>   - a human-readable tag that is practically
#                                     unique per build (commit + first 12 digest chars)
#                                     and carries traceability back to the commit
#
# Inputs (Concourse resource dirs):
#   src/.git/short_ref   - written by the git resource
#   image/digest         - written by the oci-build task (the config digest,
#                          e.g. "sha256:abc123..."). This is the config digest,
#                          not the registry manifest digest, but it is equally
#                          unique per image build for tagging purposes.
#
# Params:
#   TAG_PREFIX           - optional; must match the `tag_prefix` set on the
#                          registry-image `put` step (e.g. "staging-"). Used only
#                          to validate the final pushed tag length; the prefix
#                          itself is applied by the resource, not this script.
#
# Output:
#   tags/additional_tags - whitespace-separated tag list

SHORT_REF_FILE="src/.git/short_ref"
DIGEST_FILE="image/digest"
OUTPUT_FILE="tags/additional_tags"

# OCI / ECR image tags are limited to 128 characters, and must match
# [a-zA-Z0-9_][a-zA-Z0-9._-]{0,127}.
MAX_TAG_LENGTH=128

# Prefix the resource will prepend to each tag via `tag_prefix`. Defaults to
# empty (the `main` job pushes unprefixed tags).
TAG_PREFIX="${TAG_PREFIX:-}"

if [[ ! -f "${SHORT_REF_FILE}" ]]; then
  echo "error: ${SHORT_REF_FILE} not found" >&2
  exit 1
fi

if [[ ! -f "${DIGEST_FILE}" ]]; then
  echo "error: ${DIGEST_FILE} not found" >&2
  exit 1
fi

short_ref="$(tr -d '[:space:]' < "${SHORT_REF_FILE}")"

# The digest file looks like "sha256:<64 hex chars>". Strip the algorithm
# prefix so it is usable as an OCI tag (tags may not contain ':').
raw_digest="$(tr -d '[:space:]' < "${DIGEST_FILE}")"
full_digest="${raw_digest#sha256:}"

if [[ -z "${short_ref}" ]]; then
  echo "error: short_ref is empty" >&2
  exit 1
fi

if [[ -z "${full_digest}" ]]; then
  echo "error: image digest is empty" >&2
  exit 1
fi

# First 12 hex characters, matching the length Docker shows for short digests.
short_digest="${full_digest:0:12}"
readable_tag="${short_ref}-${short_digest}"

# Validate that every tag, once the resource applies TAG_PREFIX, stays within
# the OCI/ECR 128-character limit. Fail closed rather than let the push fail
# opaquely at the registry.
for tag in "${full_digest}" "${readable_tag}"; do
  effective_tag="${TAG_PREFIX}${tag}"
  tag_length="${#effective_tag}"
  if (( tag_length > MAX_TAG_LENGTH )); then
    echo "error: tag '${effective_tag}' is ${tag_length} characters, exceeding the ${MAX_TAG_LENGTH}-character OCI/ECR limit" >&2
    exit 1
  fi
done

mkdir -p tags
printf '%s %s' "${full_digest}" "${readable_tag}" > "${OUTPUT_FILE}"

echo "Generated image tags (tag_prefix='${TAG_PREFIX}'):"
echo "  config digest:  ${TAG_PREFIX}${full_digest}"
echo "  readable:       ${TAG_PREFIX}${readable_tag}"
