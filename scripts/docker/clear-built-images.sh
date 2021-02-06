#!/bin/bash

# {{{ Source and define everything base
CURRENT_DIR=$(dirname "$0")
BASE_DIR=$(realpath "${CURRENT_DIR}/../..")

CONFIG_FILE_PATH="${BASE_DIR}/config-generated.json"

# All below are depending on BASE_DIR to be proerly set.
FILES_DIR="${BASE_DIR}/docker"
SHAREDFS_DIR="${FILES_DIR}/sharedfs"
LIBS_DIR="${SHAREDFS_DIR}/libs"

# Load libs
. "${LIBS_DIR}/liblog.sh"
. "${LIBS_DIR}/libutil.sh"
# }}}

warn "Will remove all built images."
yes_or_exit "Continue?"

cd "${BASE_DIR}/" && make compile_configs
ALL_PROJECTS=$(jq -r '.AYAQA_BUILD_VARS | to_entries | reverse[] | .value.AYAQA_INFRA_IMAGE_NAME' ${CONFIG_FILE_PATH})
for image_name in $ALL_PROJECTS; do
    info "Checking if ${image_name} is built"
    IMAGE_ID=$(docker images --filter=reference=${image_name} --format "{{.ID}}")
    if [ ! -z "$IMAGE_ID" ]; then
        info "Image ${image_name} image ID: ${IMAGE_ID} will be removed."
        docker rmi "${IMAGE_ID}" --force
    fi
done
make clear_after_build_local
cd -