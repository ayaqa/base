#!/bin/bash

# {{{ Source and define everything base
CURRENT_DIR=$(dirname "$0")
BASE_DIR="${CURRENT_DIR}"

# All below are depending on BASE_DIR to be proerly set.
DOCKER_DIR="${BASE_DIR}/docker"
SHAREDFS_DIR="${DOCKER_DIR}/sharedfs"
LIBS_DIR="${SHAREDFS_DIR}/libs"

CONFIG_FILE_PATH="${BASE_DIR}/config-generated.json"

# Load liblog.sh
source "${LIBS_DIR}/liblog.sh"
# }}}

function docker_image_exist() {
    local IMAGE_NAME=$1
    local IMAGE_TAG=$2
    local IMAGE_BUILD_FOLDER=$3
    local DEFAULT="n"

    docker image inspect "${IMAGE_NAME}:${IMAGE_TAG}" &>/dev/null
    if [ $? != 0 ]; then
        warn "${IMAGE_NAME} - image is not found locally!"
        read -r -p "Build it? [Y/n] " build_image
        build_image="${build_image:-${DEFAULT}}"
        if [[ "$build_image" =~ ^([yY][eE][sS]|[yY])$ ]]; then
            docker_build_image ${IMAGE_BUILD_FOLDER} ${IMAGE_NAME}
        else
            log_error "${IMAGE_NAME} - build was cancelled."
            exit 1
        fi
    else
        log_ok "${IMAGE_NAME} image is built."
    fi
}

function docker_build_image() {
    local IMAGE_DIR=$1
    local IMAGE_NAME=$2
    info "Start building of: '${IMAGE_NAME}'"
    cd "${BASE_DIR}/" && make build_local IMAGE_NAME=${IMAGE_DIR}
    if [ $? != 0 ]; then
        cd -
        log_error "Cannot build ${IMAGE_NAME}"
        exit 1
    fi
    cd -
}

# Make sure local registry is running
info "Check if local registry is running."
docker ps | grep -qw registry
if [ $? != 0 ]; then
    warn "Starting local registry on port: 5001"
    docker run -d -p 5001:5000 --restart=always --name registry registry
else
    log_ok "Local registry is running."
fi

cd "${BASE_DIR}/" && make compile_configs
ALL_IMAGES=$(cat ${CONFIG_FILE_PATH} | jq -c '.AYAQA_BUILD_VARS | to_entries | .[]')
for row in $ALL_IMAGES; do
    IMAGE_FOLDER=$(jq -r '.key' <<< ${row})
    IMAGE_NAME=$(jq -r '.value | .AYAQA_PROJECT_NAME' <<< ${row})
    IMAGE_TAG=$(jq -r '.value | .AYAQA_PROJECT_TAG' <<< ${row})

    docker_image_exist $IMAGE_NAME $IMAGE_TAG $IMAGE_FOLDER
done
make clear_after_build_local
cd -