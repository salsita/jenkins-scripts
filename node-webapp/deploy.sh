#!/bin/bash
set -e
set -x

# Load common variables.
source common.sh

# Stop the old server.
sudo stop node-webapp INST=${UPSTART_INST} || true

# Wait for the process to be stopped
sleep 5

# Re-tag the image with the built app. We're doing this in the deploy step
# because only here it is that we know the build is OK (tests have passed etc.)
# so we can safely re-deploy this build when the Docker server reboots.
$DOCKER tag ${IMAGE_TAG_BUILD} ${IMAGE_TAG}

# Start the new build.
sudo start node-webapp INST=${UPSTART_INST} DOCKER_OPTS="${docker_opts}" 

# Give it time to start (or fail while starting).
sleep 5

# Output the upstart log to the console to allow debugging.
sudo tail -50 /var/log/upstart/node-webapp-${UPSTART_INST}.log

# Check it's really running.
status node-webapp INST=${UPSTART_INST} | grep 'running'
RC=$?

# Allow users to see logs in the Jenkins workspace (symlink LOG_DIR into
# the workspace). Cleaning the workspace will just remove the symlink.
pushd ${WORKSPACE}
if [ -d "${LOG_DIR}" ] && [ ! -L "./.docker_logs" ]; then
  ln -s "${LOG_DIR}" ./.docker_logs
fi
popd

exit ${RC}
