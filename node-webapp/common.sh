#!/bin/bash
set -e
set -x

# This file should be idempotent. It's sourced from various other scripts.

DOCKER="docker"

IMAGE_TAG="${service}-${environment}"
IMAGE_TAG_BUILD="${service}-${environment}-current-build"

# hash part for unguessable public path
IMAGE_HASH_KEY="c4f888a898684cac7539e6d03a255283"
IMAGE_HASH=`echo "${IMAGE_TAG}" | openssl sha256 -hmac "${IMAGE_HASH_KEY}" | cut -d' ' -f2 | head -c 8`

CID_DIR="${WORKSPACE}/../cids"
DATA_DIR="${WORKSPACE}/../data"
ARTIFACTS_DIR="${DATA_DIR}/artifacts"
ARTIFACTS_PUBLIC_DIR="/var/www/artifacts/${IMAGE_TAG}-${IMAGE_HASH}"
CACHE_DIR="${WORKSPACE}/../data/cache"
BUILD_SCRIPTS_DIR="${WORKSPACE}/../jenkins_scripts/node_webapp"

UPSTART_INST="${service}#${environment}"
DOCKER_DEFAULT_OPTS="-e NODE_ENV=${environment} -e DEPLOY_DATA_DIR=/data \
  -e DEPLOY_CACHE_DIR=/data/cache -e PROJECT_ROOT=/srv/project"

if [ -d ${BUILD_SCRIPTS_DIR} ]; then
  DOCKER_DEFAULT_OPTS="${DOCKER_DEFAULT_OPTS} -v ${BUILD_SCRIPTS_DIR}:/build/scripts"
fi;

sudo chown jenkins-slave:jenkins-slave ${WORKSPACE}/.. ${DATA_DIR} || true
mkdir -p ${CID_DIR}
mkdir -p ${DATA_DIR}
mkdir -p ${CACHE_DIR}
