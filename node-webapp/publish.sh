#!/bin/bash
set -e
set -x

# load common variables
source common.sh

# parse version from package.json
PACKAGE_JSON_FILE="${WORKSPACE}/package.json"
if [[ -f ${PACKAGE_JSON_FILE} ]]; then
  VERSION=`cat "${PACKAGE_JSON_FILE}" | ruby -r json -e 'puts JSON.parse(STDIN.read)["version"]'`
fi

# if there is one artifact file, we will use it
# if there are any dirs or more files, they should be archived first
FILES_COUNT=`find "${ARTIFACTS_DIR}" -maxdepth 1 -type f | wc -l`
DIRS_COUNT=`find "${ARTIFACTS_DIR}" -maxdepth 1 -type d -not -path "${ARTIFACTS_DIR}" | wc -l`

set +e
[[ ${FILES_COUNT} -eq 1 && ${DIRS_COUNT} -eq 0 ]]
ONE_FILE=$?
set -e

# create version tag
if [ ${VERSION} ]; then
  ARTIFACT_VERSION="-${VERSION}"
fi
ARTIFACT_BUILD="+${BUILD_NUMBER}"

# append version tag
if [ ${ONE_FILE} -eq 0 ]; then
  ARTIFACT=`ls "${ARTIFACTS_DIR}"`

  if [ ${ARTIFACT_VERSION} ]; then
    if echo "${ARTIFACT}" | grep -Fq "${ARTIFACT_VERSION}"; then
      ARTIFACT_PUBLIC=`echo "${ARTIFACT}" | sed "s/${ARTIFACT_VERSION}/${ARTIFACT_VERSION}${ARTIFACT_BUILD}/"`
    else
      ARTIFACT_PUBLIC=`echo "${ARTIFACT}" | sed "s/\./${ARTIFACT_VERSION}${ARTIFACT_BUILD}\./"`
    fi
  else
    ARTIFACT_PUBLIC=`echo "${ARTIFACT}" | sed "s/\./${ARTIFACT_BUILD}\./"`
  fi
else
  ARTIFACT_PUBLIC="${IMAGE_TAG}${ARTIFACT_VERSION}${ARTIFACT_BUILD}.tar.gz"
fi

# publish artifact
cd "${ARTIFACTS_DIR}"
mkdir -p "${ARTIFACTS_PUBLIC_DIR}"

if [ ${ONE_FILE} -eq 0 ]; then
  cp "${ARTIFACT}" "${ARTIFACTS_PUBLIC_DIR}/${ARTIFACT_PUBLIC}"
else
  tar cvzf "${ARTIFACTS_PUBLIC_DIR}/${ARTIFACT_PUBLIC}" *
fi

echo "Artifact file published: ${ARTIFACTS_DIR}/${ARTIFACT} => ${ARTIFACTS_PUBLIC_DIR}/${ARTIFACT_PUBLIC}"
