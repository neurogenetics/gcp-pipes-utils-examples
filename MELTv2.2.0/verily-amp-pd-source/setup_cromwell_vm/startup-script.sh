#!/bin/bash

set -o errexit
set -o nounset

# Setup script for installing and setting up:
# - Cromwell
#   - With a MySQL backend
#   - Configured for Pipelines API
# - Job Manager
#   - Backed by Cromwell

# Software components go to:
readonly INSTALL_ROOT=/install

# Install:
# - less
# - git
# - docker
# - docker compose

apt-get update

apt-get install --yes less
apt-get install --yes git

# Install Docker
apt-get install --yes \
     apt-transport-https \
     ca-certificates \
     curl \
     gnupg2 \
     software-properties-common
curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg | sudo apt-key add -
add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") \
   $(lsb_release -cs) \
   stable"

apt-get update

# Docker install produces an error, but appears to be fine (so ignore it):
#   Errors were encountered while processing:
#    docker-ce
#   E: Sub-process /usr/bin/dpkg returned an error code (1)
#   Return code 100.
apt-get install --yes docker-ce || true

# Install docker-compose via pip
apt-get install --yes python-pip
#pip install docker-compose
curl -L https://github.com/docker/compose/releases/download/1.23.2/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose


# Install our software
mkdir -p "${INSTALL_ROOT}"
cd "${INSTALL_ROOT}"

# Get Cromwell
git clone https://github.com/broadinstitute/cromwell.git
# Get Job Manager
git clone https://github.com/DataBiosphere/job-manager.git 

# Create a writeable directory for configuration
mkdir -p --mode 777 "${INSTALL_ROOT}/workspace/config"

# Create a writeable directory for MySQL database files
mkdir -p --mode 777 "${INSTALL_ROOT}/workspace/database"

# Create a writeable directory for log files
mkdir -p --mode 777 "${INSTALL_ROOT}/workspace/logs"

# Write a file to indicate that the startup-script is complete
touch "${INSTALL_ROOT}/workspace/logs/startup-script-complete.log"
