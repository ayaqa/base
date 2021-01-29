#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

# export term to fix tput issue
export TERM=xterm

. ${AYAQA_INFRA_LIBS_DIR}/liblog.sh

info "Run git clone of dev repo."
ansible-playbook --tags "debug_info" ${AYAQA_PROVISION_IMAGE_DIR}/clone.yml
ansible-playbook --tags "provision" ${AYAQA_PROVISION_IMAGE_DIR}/clone.yml

info "Run build and prepare app for production."
ansible-playbook --tags "debug_info" ${AYAQA_PROVISION_IMAGE_DIR}/build.yml
ansible-playbook --tags "provision" ${AYAQA_PROVISION_IMAGE_DIR}/build.yml

info "Configure nginx vhost to be builtin too."
ansible-playbook --tags "debug_info" ${AYAQA_INFRA_PROVISION_SHARED_DIR}/provision.yml
ansible-playbook --tags "nginx_vhost" ${AYAQA_INFRA_PROVISION_SHARED_DIR}/provision.yml

info "Call all provision files to clear everything that is not needed for prod build."
shopt -s globstar
for i in ${AYAQA_INFRA_PROVISION_DIR}/*/*.yml; do
    info "Call playbook: ${i}"
    ansible-playbook --tags "clean" "${i}"
done
shopt -u globstar