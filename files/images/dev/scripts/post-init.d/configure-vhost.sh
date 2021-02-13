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

info "User provided NGINX vhosts provision"
ansible-playbook --tags "nginx_vhost" ${AYAQA_INFRA_PROVISION_SHARED_DIR}/provision.yml