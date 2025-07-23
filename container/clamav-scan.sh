#!/bin/bash

echo "Updating packages"
apt-get -qq update
apt-get -y -qq install \
  clamav clamav-daemon

# Update config file
sed -i 's|/var/run/clamav/clamd.ctl|/tmp/clamd.socket|' /etc/clamav/clamd.conf

cat << EOF >> /etc/clamav/clamd.conf
ExcludePath ^/tmp/
ExcludePath ^/sys/
ExcludePath ^/proc/
ExcludePath ^/dev/
EOF

# Update database and run clamav scan
echo "Running database check"
freshclam

echo "Starting clamd"
clamd

echo "Running clamav scan"
clamdscan --multiscan --fdpass /*

echo "Clamav scan is done"
