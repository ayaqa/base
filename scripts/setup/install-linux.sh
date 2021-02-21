#!/bin/bash

# {{{ Source and define everything base
CURRENT_DIR=$(dirname "$0")
BASE_DIR="${CURRENT_DIR}/../.."

# All below are depending on BASE_DIR to be proerly set.
FILES_DIR="${BASE_DIR}/files"
SHAREDFS_DIR="${FILES_DIR}/sharedfs"
LIBS_DIR="${SHAREDFS_DIR}/libs"

# Load liblog.sh
source "${LIBS_DIR}/liblog.sh"
# }}}

# Load linux fnc used here.
source "${CURRENT_DIR}/fnc/linux.sh"

if [[ "$OSTYPE" != "linux-gnu"* ]]; then
    echo "That script is working only on ubuntu/debian."
    exit 1;
fi;

warn "Verifying that everything needed is installed on ubntu/debian."

# Check if scripts is running as root.
info "Check for root user"
if [ "$(whoami)" = "root" ]; then
    log_error "That script should not run as root, but sudo may be required on some steps"
    exit 1
fi

# Update apt
log_warn "Update apt packages. Will ask for sudo on next step."
sudo apt-get update

# Verify common
log_warn "Verifying install of common system dependencies."
check_and_install_apt 'curl apt-transport-https ca-certificates software-properties-common golang-go unzip'

# Verify all required for build process is there.
log_warn "Verifying install of required software."
check_and_install_apt 'docker-ce docker-ce-cli packer jq'

# Verify all binaries are there
log_warn "Checking all required binares are there."
verify_binaries 'docker docker-compose jq packer'