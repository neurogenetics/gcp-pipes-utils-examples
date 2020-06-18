#!/bin/bash

set -o errexit
set -o nounset

readonly BATCH_ID=1
readonly DIR="./samples/batch-${BATCH_ID}"

readonly SAMPLES=(
SH-00-34
SH-00-38
SH-00-49
SH-98-23
SH-98-32
SH-99-02
SH-99-14
SH-99-29
SH-99-31
SH-99-44
)
readonly INPUT_ROOT=gs://v-amp-pd-test-us-central/unmapped
readonly OUTPUT_ROOT=gs://v-amp-pd-test-us-central/batch-"${BATCH_ID}"

for SAMPLE_ID in "${SAMPLES[@]}"; do
  SAMPLE_DIR="${DIR}/${SAMPLE_ID}"
  mkdir -p "${SAMPLE_DIR}"

  # Create the labels.json
  SAMPLE_ID_LOWER="$(echo "${SAMPLE_ID}" | tr '[:upper:]' '[:lower:]')"
  python substitute.py \
    --template-file templates/PairedEndSingleSampleWf.labels.json \
    --variables \
      batch_id="${BATCH_ID}" \
      sample_id="${SAMPLE_ID_LOWER}" \
  > "${SAMPLE_DIR}/${SAMPLE_ID}.labels.json"

  # Create the inputs.json
  python substitute.py \
    --template-file templates/PairedEndSingleSampleWf.inputs.json \
    --variables \
      sample_id="${SAMPLE_ID}" \
      ubams="$(gsutil ls "${INPUT_ROOT}/${SAMPLE_ID}/*.bam" \
               | sed -e 's#\(.*\)#    "\1"#' -e '$!s#$#,#')" \
  > "${SAMPLE_DIR}/${SAMPLE_ID}.inputs.json"

  # Create the options.json
  python substitute.py \
    --template-file templates/PairedEndSingleSampleWf.options.json \
    --variables \
      output_root="${OUTPUT_ROOT}" \
      sample_id="${SAMPLE_ID}" \
  > "${SAMPLE_DIR}/${SAMPLE_ID}.options.json"

done
