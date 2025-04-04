#!/bin/bash

echo "Updating packages"
apt-get -qq update
apt-get -y -qq install \
  clamav clamav-daemon

# Update database and run clamav scan
echo "Running database check"
freshclam

echo "Running clamav scan"
clamscan --exclude /sys -r -i /

echo "Clamav scan is done"
