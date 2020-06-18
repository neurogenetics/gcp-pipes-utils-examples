#!/bin/bash

set -o errexit
set -o nounset

readonly INSTANCE=${1:-${USER}-cromwell}
readonly PROJECT=${2:-verily-amp-pd-test}
readonly MACHINE_TYPE=${3:-n1-highmem-2}

gcloud --project "${PROJECT}" \
  compute instances create "${INSTANCE}" \
  --machine-type "${MACHINE_TYPE}" \
  --scopes="https://www.googleapis.com/auth/compute,https://www.googleapis.com/auth/devstorage.read_write,https://www.googleapis.com/auth/genomics,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write" \
  --boot-disk-size=500GB \
  --metadata-from-file startup-script=./startup-script.sh

echo
echo "Now run"
echo
echo "./configure.sh ${INSTANCE} ${PROJECT}"

echo
echo "When that is up, ssh to the instance:"
echo
echo "gcloud --project ${PROJECT} compute ssh ${INSTANCE}"

echo
echo "And in that SSH session, run:"
echo "cd /install"
echo "docker-compose -f /install/workspace/config/docker-compose.yml up"

echo
echo "When cromwell is up, create an SSH tunnel from your workstation:"

echo "
gcloud --project ${PROJECT} \\
  compute ssh ${INSTANCE} \\
  -- -L 8000:localhost:8000"

echo
echo "And then in a brower connect to http://localhost:8000"

echo
