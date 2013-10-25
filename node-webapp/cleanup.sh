#!/bin/bash
set -e
set -x

# Load common variables.
source common.sh

if [ `$DOCKER images | grep ${IMAGE_TAG}` -eq 0 ]; then
  # Remove the build image.
  $DOCKER rmi ${IMAGE_TAG_BUILD}
fi

# Remove the containers to free disk space.
for cidfile in `ls ${CID_DIR}`; do
  $DOCKER rm `cat ${CID_DIR}/${cidfile}`
  rm -f ${cidfile}
done
