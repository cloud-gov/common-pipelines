#!/bin/bash

echo "Updating packages"
apt-get -qq update
apt-get -y -qq install \
  clamav

# Update database and run clamav scan
echo "Running database check"
freshclam

echo "Running clamav scan"
clamscan -r -i /

echo "Clamav scan is done"
