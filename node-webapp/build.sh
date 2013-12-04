#!/bin/bash
set -e
set -x

# Load common variables.
source common.sh

cd ${WORKSPACE}

### Build the new Docker image to use for the job.
$DOCKER build -t ${IMAGE_TAG_BUILD} .

CONTAINER=$( \
  $DOCKER run -d \
  -v "${DATA_DIR}:/data" ${DOCKER_DEFAULT_OPTS} ${docker_opts} \
  ${IMAGE_TAG_BUILD} \
  /bin/bash -c "cd /build/scripts/plugins/pre-build && /bin/bash cache_node_modules.sh")
${DOCKER} attach ${CONTAINER} 
${DOCKER} wait ${CONTAINER}
${DOCKER} commit ${CONTAINER} ${IMAGE_TAG_BUILD}

# Run in the background so that we know the container id.
CONTAINER=$( \
  $DOCKER run -cidfile ${CID_DIR}/build-${BUILD_NUMBER}.cid -d \
  -v "${DATA_DIR}:/data" \
  ${DOCKER_DEFAULT_OPTS} \
  ${docker_opts} ${IMAGE_TAG_BUILD} \
  /bin/bash -c "cd /srv/project/deploy && make build")

$DOCKER attach ${CONTAINER} 

RC=$($DOCKER wait ${CONTAINER})

sudo chown -R jenkins-slave:jenkins-slave ${WORKSPACE}
sudo chown -R jenkins-slave:jenkins-slave ${DATA_DIR}

if [ $RC -ne 0 ]; then
  exit $RC;
fi

# Commit the built app container to an image.
$DOCKER commit ${CONTAINER} ${IMAGE_TAG_BUILD}
