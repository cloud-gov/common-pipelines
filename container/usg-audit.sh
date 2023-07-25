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

apt-get update
apt-get -y upgrade
apt-get -y -q install \
  ubuntu-advantage-tools \
  ca-certificates \
  python3-pip

echo "UA attaching"
ua attach --attach-config ua-attach-config.yaml

apt-get -y -q install usg

echo "installing bs4"
# Install the python library BeautifulSoup to parse html
pip3 install beautifulsoup4

# Run cis audit and put html results into cis-audit.html file
echo "running audit"
usg audit cis_level1_server --html-file $PWD/audit/cis-audit.html --results-file $PWD/audit/cis-audit.xml

# Parse the resulting cis-audit.html file looking for pass/fail via a python script
if [ "$(./common-pipelines/container/parse_cis_audit_html.py --inputfile audit/cis-audit.html)" == "failed" ]
then
  echo "Container hardening audit FAILED"
  exit 1
fi

echo "Container hardening audit PASSED"
