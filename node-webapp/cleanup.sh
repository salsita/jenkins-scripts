#!/bin/sh

# Load common variables.
source common.sh

# Remove the build image.
$DOCKER rmi ${IMAGE_TAG_BUILD}

# Remove the containers to free disk space.
for cidfile in `ls ${CID_DIR}`; do
  $DOCKER rm `cat ${CID_DIR}/${cidfile}`
  rm -f ${cidfile}
done
