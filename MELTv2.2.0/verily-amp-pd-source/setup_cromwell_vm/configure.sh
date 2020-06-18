#!/bin/bash

set -o errexit
set -o nounset

readonly INSTANCE="${1:-${USER}-cromwell}"
readonly PROJECT="${2:-verily-amp-pd-test}"
readonly BUCKET="${3:-v-amp-pd-test-data}"

readonly INSTALL_ROOT=/install

while ! gcloud --project "${PROJECT}" \
          compute ssh "${INSTANCE}" \
          --command "[[ -f ${INSTALL_ROOT}/workspace/logs/startup-script-complete.log ]]"; do
  echo "Waiting for startup-script to complete"
  sleep 5
done

echo "Add the user to the docker group"
gcloud --project "${PROJECT}" \
  compute ssh "${INSTANCE}" \
  --command 'sudo usermod -aG docker "${USER}"'

echo "Configure the Cromwell config template"
sed \
  -e "s#__PROJECT__#${PROJECT}#" \
  -e "s#__BUCKET__#${BUCKET}#" \
  ./config/google.conf.tmpl > ./config/google.conf

echo "Copy up the Cromwell config template"
gcloud --project "${PROJECT}" \
  compute scp \
  ./config/google.conf \
  "${INSTANCE}":"${INSTALL_ROOT}"/workspace/config/ && \
  rm ./config/google.conf

echo "Configure the docker-compose.yml file"
gcloud --project "${PROJECT}" \
  compute scp \
  ./config/docker-compose.yml \
  "${INSTANCE}":"${INSTALL_ROOT}"/workspace/config/

echo "Configuration complete"
