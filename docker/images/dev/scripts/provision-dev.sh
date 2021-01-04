#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

# export term to fix tput issue
export TERM=xterm

. ${AYAQA_INFRA_LIBS_DIR}/liblog.sh

info "Run provision for php"
ansible-playbook --tags "debug_info" ${AYAQA_PROVISION_IMAGE_DIR}/php.yml
ansible-playbook --tags "provision" ${AYAQA_PROVISION_IMAGE_DIR}/php.yml

info "Run provision for phpfpm and nginx"
ansible-playbook --tags "debug_info" ${AYAQA_PROVISION_IMAGE_DIR}/phpfpm-nginx.yml
ansible-playbook --tags "provision" ${AYAQA_PROVISION_IMAGE_DIR}/phpfpm-nginx.yml

info "Run provision for supervisor"
ansible-playbook --tags "debug_info" ${AYAQA_PROVISION_IMAGE_DIR}/supervisor.yml
ansible-playbook ${AYAQA_PROVISION_IMAGE_DIR}/supervisor.yml