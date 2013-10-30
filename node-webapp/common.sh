#!/bin/bash
set -e
set -x

# This file should be idempotent. It's sourced from various other scripts.

DOCKER="docker -H tcp://127.0.0.1:4245"

IMAGE_TAG="${service}-${environment}"
IMAGE_TAG_BUILD="${service}-${environment}-current-build"

# hash part for unguessable public path
IMAGE_HASH_KEY="c4f888a898684cac7539e6d03a255283"
IMAGE_HASH=`echo "${IMAGE_TAG}" | openssl sha256 -hmac "${IMAGE_HASH_KEY}" | cut -d' ' -f2 | head -c 8`

CID_DIR="${WORKSPACE}/../cids"
DATA_DIR="${WORKSPACE}/../data"
ARTIFACTS_DIR="${DATA_DIR}/artifacts"
ARTIFACTS_PUBLIC_DIR="/var/www/artifacts/${IMAGE_TAG}-${IMAGE_HASH}"

UPSTART_INST="${service}#${environment}"

mkdir -p ${CID_DIR}
mkdir -p ${DATA_DIR}
