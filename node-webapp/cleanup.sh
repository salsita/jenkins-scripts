#!/bin/bash
set -e
set -x

# Load common variables.
source common.sh

sudo chown -R jenkins-slave:jenkins-slave ${WORKSPACE}

rm -f ${CID_DIR}/*

# Remove artifacts
rm -rf ${ARTIFACTS_DIR}
