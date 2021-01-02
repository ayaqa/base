#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

# export term to fix tput issue
export TERM=xterm

. ${AYAQA_INFRA_LIBS_DIR}/liblog.sh

info "Run provision with ansible"
# First will run it with debug_info to have all variables before run real provision
ansible-playbook --tags "debug_info" ${AYAQA_PROVISION_IMAGE_DIR}/internal.yml
ansible-playbook --tags "provision" ${AYAQA_PROVISION_IMAGE_DIR}/internal.yml