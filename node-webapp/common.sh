#!/bin/bash
set -e
set -x

# This file should be idempotent. It's sourced from various other scripts.

DOCKER="docker -H tcp://127.0.0.1"

IMAGE_TAG="${service}-${environment}"
IMAGE_TAG_BUILD="${service}-${environment}-current-build"
CID_DIR="${WORKSPACE}/../cids"
DATA_DIR="${WORKSPACE}/../data"

UPSTART_INST="${service}#${environment}"

mkdir -p ${CID_DIR}
