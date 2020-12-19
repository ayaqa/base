#!/bin/bash

# {{{ Source and define everything base
CURRENT_DIR=$(dirname "$0")
BASE_DIR="${CURRENT_DIR}/../.."

# All below are depending on BASE_DIR to be proerly set.
DOCKER_DIR="${BASE_DIR}/docker"
SHAREDFS_DIR="${DOCKER_DIR}/sharedfs"
LIBS_DIR="${SHAREDFS_DIR}/libs"

# Load liblog.sh
source "${LIBS_DIR}/liblog.sh"
# }}}

# Load mac fnc used here.
source "${CURRENT_DIR}/fnc/mac.sh"

# Prevent script running on different than mac terminals.
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "That script is working only on macos."
    exit 1;
fi

warn "Verifying that everything needed is installed on macos."

# Check if scripts is running as root.
info "Check for root user"
if [ "$(whoami)" = "root" ]; then
    log_error "Running as root $0 detected."
    exit 1
fi

# Check if brew is installed
info "Check if brew is there"
if ! which brew > /dev/null; then
    log_warn "brew was not found. Will try to install it."
    log_info "Password may be needed."

    install_brew
else
    log_ok "brew is there."
fi

# Update brew packages
info "Will update brew packages..."
brew update

# Check if software exists and install (from brew cask)
check_brew_cask 'docker'

# Check if software exists and install (from brew)
check_brew 'packer jq'