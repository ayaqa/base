#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

# export term to fix tput issue
export TERM=xterm

. ${AYAQA_INFRA_LIBS_DIR}/liblog.sh
. ${AYAQA_INFRA_LIBS_DIR}/libutil.sh

info "Run provision for: php"
if [[ $(is_debug) == "true" ]]; then
    ansible-playbook --tags "debug_info" ${AYAQA_PROVISION_IMAGE_DIR}/php.yml
fi;
ansible-playbook --tags "provision" ${AYAQA_PROVISION_IMAGE_DIR}/php.yml

info "Run provision for: phpfpm and nginx"
if [[ $(is_debug) == "true" ]]; then
    ansible-playbook --tags "debug_info" ${AYAQA_PROVISION_IMAGE_DIR}/phpfpm-nginx.yml
fi;
ansible-playbook --tags "provision" ${AYAQA_PROVISION_IMAGE_DIR}/phpfpm-nginx.yml

info "Run provision for: supervisor"
if [[ $(is_debug) == "true" ]]; then
    ansible-playbook --tags "debug_info" ${AYAQA_PROVISION_IMAGE_DIR}/supervisor.yml
fi
ansible-playbook ${AYAQA_PROVISION_IMAGE_DIR}/supervisor.yml

info "Run internal provision"
if [[ $(is_debug) == "true" ]]; then
    ansible-playbook --tags "debug_info" ${AYAQA_PROVISION_IMAGE_DIR}/internal.yml
fi;
ansible-playbook --tags "provision"  ${AYAQA_PROVISION_IMAGE_DIR}/internal.yml

info "Run common provision"
if [[ $(is_debug) == "true" ]]; then
    ansible-playbook --tags "debug_info" ${AYAQA_PROVISION_IMAGE_DIR}/common.yml
fi;
ansible-playbook --tags "provision"  ${AYAQA_PROVISION_IMAGE_DIR}/common.yml