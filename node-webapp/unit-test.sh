#!/bin/bash
set -e
set -x

# Load common variables.
source common.sh

cd ${WORKSPACE}

$DOCKER run -cidfile ${CID_DIR}/test-${BUILD_NUMBER}.cid -v '${WORKSPACE}/srv/:/srv/project/' -e NODE_ENV=${environment} ${docker_opts} ${IMAGE_TAG_BUILD} /bin/bash -c "cd /srv/project/deploy && make test"

sudo chown -R jenkins-slave:jenkins-slave ${WORKSPACE}

CONTAINER=`cat ${CID_DIR}/test-${BUILD_NUMBER}.cid`

# Exit with the same value that the process exited with.
RC=$($DOCKER wait ${CONTAINER})
exit $RC
