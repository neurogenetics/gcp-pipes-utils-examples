#!/usr/bin/python

# Copyright 2018 Verily Inc.
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file or at
# https://developers.google.com/open-source/licenses/bsd

# cromwell_client.py
#
# This script provides a library interface to Cromwell, namely:
#  * Submit execution requests to Cromwell
#  * Poll Cromwell for job status

import argparse
import logging
import os
import requests
import time


class CromwellClient(object):

  def __init__(self, url='http://localhost:8000/api/workflows/v1'):
    self._url = url

  def _fetch(self, wf_id=None, post=False, files=None, method=None):
    url = self._url
    if wf_id is not None:
      url = os.path.join(url, wf_id)
    if method is not None:
      url = os.path.join(url, method)
    if post:
      r = requests.post(url, files=files)
    else:
      r = requests.get(url)
    return r.json()

  def _read_file(self, name):
    with open(name, 'rb') as f:
      return f.read()

  def submit_wdl(self, wdl, workflow_inputs, workflow_options, labels):
    """Post new job to the server and return the job identifier."""
    ### Raises:  except requests.exceptions.ConnectionError as e:

    # Build up a dictionary of files where keys are the API parameters
    files = {}

    # Add the WDL file
    files['wdlSource'] = self._read_file(wdl)

    # Add all inputs files
    for index, wf_input in enumerate(workflow_inputs):
      # The API fields are named "workflowInputs", "workflowInputs_2", etc.
      key = 'workflowInputs'
      if index > 0:
        key = 'workflowInputs_{}'.format(index + 1)

      files[key] = self._read_file(wf_input)

    # Add workflow options if specified
    if workflow_options:
      files['workflowOptions'] = self._read_file(workflow_options)

    if labels:
      files['labels'] = self._read_file(labels)

    # After Cromwell start, it may take a few seconds to be ready for requests.
    # Poll up to a minute for successful connect and submit.

    job = None
    max_time_wait = 60
    wait_interval = 5

    for attempt in range(int(max_time_wait/wait_interval) + 1):
      try:
        job = self._fetch(post=True, files=files)
        break
      except requests.exceptions.ConnectionError as e:
        logging.info("Failed to connect to Cromwell (attempt %d): %s",
          attempt + 1, e)
        time.sleep(wait_interval)

    # If after 12 attempts (60 seconds), try one more time and allow
    # the exception to be raised if it fails again.
    if not job:
      job = self._fetch(post=True, files=files)

    return job
    
  def poll(self, job, sleep_interval): 
    ### Raises:  except requests.exceptions.ConnectionError as e:

    cromwell_id = job['id']
    logging.info("Job submitted to Cromwell. job id: %s", cromwell_id)

    # Poll Cromwell for job completion.
    attempt = 0
    max_failed_attempts = 3
    while True:
      time.sleep(sleep_interval)

      # Cromwell occassionally fails to respond to the status request.
      # Only give up after 3 consecutive failed requests.
      try:
        status_json = self._fetch(wf_id=cromwell_id, method='status')
        attempt = 0
      except requests.exceptions.ConnectionError as e:
        attempt += 1
        logging.info("Error polling Cromwell job status (attempt %d): %s",
          attempt, e)

        if attempt == max_failed_attempts - 1:
          # Try without a catch
          status_json = self._fetch(wf_id=cromwell_id, method='status')

        continue

      status = status_json['status']
      if status == 'Submitted':
        pass
      elif status == 'Running':
        pass
      else:
        break

    logging.info("Cromwell job status: %s", status)

    return status

def main():
  parser = argparse.ArgumentParser(description='Run WDLs')
  parser.add_argument('--wdl', required=True,
                      help='The WDL file to run')
  parser.add_argument('--workflow-inputs', required=True, nargs='+',
                      help='The workflow inputs (JSON) file')
  parser.add_argument('--workflow-options', required=False,
                      help='The workflow options (JSON) file')
  parser.add_argument('--workflow-labels', required=False,
                      help='The workflow labels (JSON) file')
  args = parser.parse_args()

  client = CromwellClient()
  job = client.submit_wdl(args.wdl, args.workflow_inputs,
                          args.workflow_options, args.workflow_labels)
  print(job)
  #status = client.poll(job, 15)
  #print(status)


if __name__ == '__main__':
  main()
