#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

# Prevent warning for localhost
sed -i "s;#inventory      = /etc/ansible/hosts;inventory = /etc/ansible/hosts;g" /etc/ansible/ansible.cfg
echo 'localhost' > /etc/ansible/hosts

# Add ayaqa-configure roles path to default ansible roles.
sed -i "s;#roles_path    = /etc/ansible/roles;roles_path = /etc/ansible/roles:~/.ansible/roles:${ANSIBLE_ROLES};g" /etc/ansible/ansible.cfg

# First will run it with debug_info to have all variables before run real provision
ansible-playbook --tags "debug_info" ${AYAQA_PROVISION_IMAGE_DIR}/setup.yml
ansible-playbook --tags "provision" ${AYAQA_PROVISION_IMAGE_DIR}/setup.yml