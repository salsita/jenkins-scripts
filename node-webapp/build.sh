#!/bin/bash
set -e
set -x

# Load common variables.
source common.sh

# Remove the old image.
$DOCKER rmi ${IMAGE_TAG_BUILD}

### Build the new Docker image to use for the job.
$DOCKER build -rm -t ${IMAGE_TAG_BUILD} .

# Run in the background so that we know the container id.
CONTAINER=$( \
  $DOCKER run -cidfile ${CID_DIR}/build-${BUILD_NUMBER}.cid -d -e NODE_ENV=${environment} ${docker_opts} ${IMAGE_TAG_BUILD} \
  /bin/bash -c "cd /srv/project/deploy && make build")

$DOCKER attach ${CONTAINER} 

RC=$($DOCKER wait ${CONTAINER})

if [ $RC -ne 0 ]; then
  exit $RC;
fi

# Commit the built app container to an image.
$DOCKER commit ${CONTAINER} ${IMAGE_TAG_BUILD}
