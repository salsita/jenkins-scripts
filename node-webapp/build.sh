#!/bin/bash
set -e
set -x

# Load common variables.
source common.sh

cd ${WORKSPACE}

### Project-specific dependencies caching in Docker
# Project dependency definition files need to have set correct mtime,
# so Docker can cache them properly.
# This probably won't be needed in the future.
# @see https://github.com/dotcloud/docker/issues/3699
FILENAMES=(
  '.npmrc'
  '.npmignore'
  'package.json'
  '.bowerrc'
  'bower.json'
)
# find them
FIND_PARAMS="-name `echo -n ${FILENAMES[@]} | sed 's/ / -or -name /g'`"
FILES=`find . ${FIND_PARAMS}`
# allow project to specify its own files
if [ -f .docker-cache ]; then
  FILES+=($(cat .docker-cache))
fi
# set mtime from last git commit, where they changed
for FILE in ${FILES[@]}; do
  REV=`git rev-list -n 1 HEAD "${FILE}"`
  TIMESTAMP=`git show --pretty=format:%ai --abbrev-commit "${REV}" | head -n 1`
  touch -d "${TIMESTAMP}" "${FILE}"
done


### Build the new Docker image to use for the job.
$DOCKER build -t ${IMAGE_TAG_BUILD} .

# Run in the background so that we know the container id.
CONTAINER=$( \
  $DOCKER run -cidfile ${CID_DIR}/build-${BUILD_NUMBER}.cid -d \
  -v "${DATA_DIR}:/data" \
  ${DOCKER_DEFAULT_OPTS} \
  -e NODE_ENV=${environment} ${docker_opts} ${IMAGE_TAG_BUILD} \
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
