#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

# export term to fix tput issue
export TERM=xterm

. ${AYAQA_INFRA_LIBS_DIR}/liblog.sh
. ${AYAQA_INFRA_LIBS_DIR}/libutil.sh

info "Run ansible: Clone dev repository"
if [[ $(is_debug) == "true" ]]; then
    ansible-playbook --tags "debug_info" ${AYAQA_PROVISION_IMAGE_DIR}/clone.yml
fi;
ansible-playbook --tags "provision" ${AYAQA_PROVISION_IMAGE_DIR}/clone.yml

info "Run ansible: Build app for production"
if [[ $(is_debug) == "true" ]]; then
    ansible-playbook --tags "debug_info" ${AYAQA_PROVISION_IMAGE_DIR}/build.yml
fi;
ansible-playbook --tags "provision" ${AYAQA_PROVISION_IMAGE_DIR}/build.yml

info "Run ansible: Internal provision playbook"
if [[ $(is_debug) == "true" ]]; then
    ansible-playbook --tags "debug_info" ${AYAQA_PROVISION_IMAGE_DIR}/internal.yml
fi;
ansible-playbook --tags "provision"  ${AYAQA_PROVISION_IMAGE_DIR}/internal.yml

info "Run ansbile: NGINX vhost configure playbook"
if [[ $(is_debug) == "true" ]]; then
    ansible-playbook --tags "debug_info" ${AYAQA_INFRA_PROVISION_SHARED_DIR}/provision.yml
fi;
ansible-playbook --tags "nginx_vhost" ${AYAQA_INFRA_PROVISION_SHARED_DIR}/provision.yml

info "Call clean for all playbooks that are found in provision dir"
shopt -s globstar
for i in ${AYAQA_INFRA_PROVISION_DIR}/*/*.yml; do
    info "Call clean playbook for: ${i}"
    ansible-playbook --tags "clean" "${i}"
done
shopt -u globstar