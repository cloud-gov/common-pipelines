#!/bin/bash
set -eo pipefail

# set up dir and file
touch audit/$IMAGENAME-audit.html
touch audit/$IMAGENAME-audit.xml

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

#fix file permissions after running apt so audit passes properly
find /var/log -perm /137 ! -name '*[bw]tmp' ! -name '*lastlog' -type f -exec chmod 640 '{}' \;

# Run audit and put html results into audit.html file
echo "running audit"
usg audit --tailoring-file $TAILORINGFILE --html-file $PWD/audit/$IMAGENAME-audit.html --results-file $PWD/audit/$IMAGENAME-audit.xml

# Parse the resulting audit.html file looking for pass/fail via a python script
if [ "$(./common-pipelines/container/parse_usg_audit_html.py --inputfile audit/$IMAGENAME-audit.html)" == "failed" ]
then
  echo "Container hardening audit FAILED"
  exit 1
fi

echo "Container hardening audit PASSED"
