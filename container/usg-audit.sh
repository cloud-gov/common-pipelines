#!/bin/bash
set -eo pipefail

# set up dir and file
touch audit/cis-audit.html
touch audit/cis-audit.xml

echo "Configuring ua attach config"
cat <<EOF >> ua-attach-config.yaml
token: $UBUNTU_ADVANTAGE_TOKEN
enable_services:
- usg
- esm-infra
EOF

apt-get -qq update
apt-get -y -qq upgrade
apt-get -y -qq install \
  ubuntu-advantage-tools \
  ca-certificates \
  python3-pip

echo "UA attaching"
ua attach --attach-config ua-attach-config.yaml

apt-get -y -qq install usg

echo "installing bs4"
# Install the python library BeautifulSoup to parse html
python3 -m pip install beautifulsoup4

# Run cis audit and put html results into cis-audit.html file
echo "running audit"
usg audit --tailoring-file common-pipelines/container/tailor.xml --html-file /audit/$IMAGENAME-audit.html --results-file /audit/$IMAGENAME-audit.xml

# Parse the resulting cis-audit.html file looking for pass/fail via a python script
if [ "$(./common-pipelines/container/parse_cis_audit_html.py --inputfile audit/$IMAGENAME-audit.html)" == "failed" ]
then
  echo "Container hardening audit FAILED"
  exit 1
fi

echo "Container hardening audit PASSED"
