#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

# export term to fix tput issue
export TERM=xterm

. ${AYAQA_INFRA_LIBS_DIR}/liblog.sh
. ${AYAQA_INFRA_LIBS_DIR}/libutil.sh

# Prevent warning for localhost 
info "Fix localhost warning for ansible."
sed -i "s;#inventory      = /etc/ansible/hosts;inventory = /etc/ansible/hosts;g" /etc/ansible/ansible.cfg
echo 'localhost' > /etc/ansible/hosts

# Add ayaqa-configure roles path to default ansible roles.
info "Add shared roles to default role path."
sed -i "s;#roles_path    = /etc/ansible/roles;roles_path = /etc/ansible/roles:~/.ansible/roles:${ANSIBLE_ROLES};g" /etc/ansible/ansible.cfg

info "Run provision with ansible"
# First will run it with debug_info to have all variables before run real provision
if [[ $(is_debug) == "true" ]]; then
    ansible-playbook --tags "debug_info" ${AYAQA_PROVISION_IMAGE_DIR}/internal.yml
fi;
ansible-playbook --tags "provision" ${AYAQA_PROVISION_IMAGE_DIR}/internal.yml

# All external roles for ansible will be executed after interla ones.
if [[ $(is_debug) == "true" ]]; then
    ansible-playbook --tags "debug_info" ${AYAQA_PROVISION_IMAGE_DIR}/external.yml
fi;
ansible-playbook --skip-tags "debug_info" ${AYAQA_PROVISION_IMAGE_DIR}/external.yml

info "Fix supervisor pid file location."
# Replace .pid location
sed -i "s#pidfile = /var/run/supervisord.pid#pidfile = ${AYAQA_RUN_FOLDER}/supervisord.pid#" /etc/supervisor/supervisord.conf