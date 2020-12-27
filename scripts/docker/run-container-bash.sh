#!/bin/bash

# {{{ Source and define everything base
CURRENT_DIR=$(dirname "$0")
BASE_DIR=$(realpath "${CURRENT_DIR}/../..")


# All below are depending on BASE_DIR to be proerly set.
DOCKER_DIR="${BASE_DIR}/docker"
SHAREDFS_DIR="${DOCKER_DIR}/sharedfs"
LIBS_DIR="${SHAREDFS_DIR}/libs"

# Load libs
. "${LIBS_DIR}/liblog.sh"
. "${LIBS_DIR}/libutil.sh"
# }}}

info "Run container with entrypoint bash."
DOCKER_EXEC=$(find_full_path docker)

${DOCKER_EXEC} run -ti --entrypoint /bin/bash $@
