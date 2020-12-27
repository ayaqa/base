#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

# Prevent warning for localhost
sed -i "s;#inventory      = /etc/ansible/hosts;inventory = /etc/ansible/hosts;g" /etc/ansible/ansible.cfg
echo 'localhost' > /etc/ansible/hosts

# First will run it with debug_info to have all variables before run real provision
ansible-playbook --tags "debug_info" ${AYAQA_PROVISION_IMAGE_DIR}/setup.yml