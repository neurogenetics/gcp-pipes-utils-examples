#!/bin/bash

set -o errexit
set -o nounset

readonly BATCH="${1}"
readonly SAMPLE="${2}"

python ~/wdl_workflow_runner/cromwell_client.py \
  --wdl workflows/PairedEndSingleSampleWf/PairedEndSingleSampleWf.wdl \
  --workflow-inputs \
     workflows/PairedEndSingleSampleWf/PairedEndSingleSampleWf.hg38.inputs.json \
     "samples/${BATCH}/${SAMPLE}/${SAMPLE}.inputs.json" \
  --workflow-options "samples/${BATCH}/${SAMPLE}/${SAMPLE}.options.json" \
  --workflow-labels "samples/${BATCH}/${SAMPLE}/${SAMPLE}.labels.json"

