#!/bin/bash
set -e
set -x

# Load common variables.
source common.sh

sudo chown -R jenkins-slave:jenkins-slave ${WORKSPACE}

# Remove artifacts
rm -rf ${ARTIFACTS_DIR}
