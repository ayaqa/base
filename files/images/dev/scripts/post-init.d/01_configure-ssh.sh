#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

. ${AYAQA_INFRA_LIBS_DIR}/liblog.sh
. ${AYAQA_INFRA_LIBS_DIR}/libutil.sh

if [[ $(is_debug) == "true" ]]; then
    info "DEBUG INFO"
    ansible-playbook --tags "debug_info" ${AYAQA_INFRA_PROVISION_SHARED_DIR}/provision.yml
fi;

info "Run ansible: SSH config if provided (via volume mount)"
ansible-playbook --tags "ssh_config" ${AYAQA_INFRA_PROVISION_SHARED_DIR}/provision.yml