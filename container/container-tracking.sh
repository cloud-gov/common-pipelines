#!/bin/bash
set -eo pipefail

curl -o fly "${ATC_URL}/api/v1/cli?arch=amd64&platform=linux"
chmod +x fly
mv fly /usr/local/bin/

(
  set +x
  fly --target ci login \
    --concourse-url "${ATC_URL}" \
    --username "${CONCOURSE_AUTH_USERNAME}" \
    --password "${CONCOURSE_AUTH_PASSWORD}"
)

./cg-scripts/concourse/get-pipeline-container-images.sh
