#!/bin/bash
set -e
set -x

# Load common variables.
source common.sh

cd ${WORKSPACE}

$DOCKER run -cidfile ${CID_DIR}/test-${BUILD_NUMBER}.cid -e NODE_ENV=${environment} ${docker_opts} ${IMAGE_TAG_BUILD} /bin/bash -c "cd /srv/project/deploy && make test"

CONTAINER=`cat ${CID_DIR}/test-${BUILD_NUMBER}.cid`

IMAGE=$($DOCKER commit ${CONTAINER})
set +e
TEST_RESULTS=$($DOCKER run -cidfile ${CID_DIR}/find-test-${BUILD_NUMBER}.cid ${docker_opts} ${IMAGE} /bin/bash -c "find /srv/project/ -name 'test-results*.xml' | grep -v node_modules")
set -e

# Delete the old test results (just in case we're not deleting the workspace).
# If we didn't do that, the old test results would be copied into the Dicker container
# and Jenkins would complain it's an old result. Ugh.
rm -f test-results*.xml

# Copy the test results to the host machine.
for TEST_FILE in ${TEST_RESULTS}; do
  $DOCKER cp ${CONTAINER}:${TEST_FILE} ${WORKSPACE}/
done

# Exit with the same value that the process exited with.
RC=$($DOCKER wait ${CONTAINER})
exit $RC
