#!/bin/bash

# {{{ Source and define everything base
CURRENT_DIR=$(dirname "$0")
BASE_DIR="${CURRENT_DIR}"

# All below are depending on BASE_DIR to be proerly set.
DOCKER_DIR="${BASE_DIR}/docker"
SHAREDFS_DIR="${DOCKER_DIR}/sharedfs"
LIBS_DIR="${SHAREDFS_DIR}/libs"

# Load liblog.sh
source "${LIBS_DIR}/liblog.sh"
# }}}

# Make sure local registry is running
info "Check if local registry is running."
docker ps | grep -qw registry
if [ $? != 0 ]; then
    warn "Starting local registry on port: 5001"
    docker run -d -p 5001:5000 --restart=always --name registry registry
else
    log_ok "Local registry is running."
fi