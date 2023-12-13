#!/bin/bash
set -eo pipefail

apt-get -qq update
apt-get -y -qq upgrade
apt-get -y -qq install \
  net-tools

echo "List of open ports: "

netstat -tulpn | grep LISTEN
