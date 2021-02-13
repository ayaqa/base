#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

. ${AYAQA_INFRA_LIBS_DIR}/liblog.sh
. ${AYAQA_INFRA_LIBS_DIR}/libfs.sh

# source dumped vars
. ~/.bashrc

# on boot user provided sh scripts
. ${AYAQA_ON_BOOT_RUN_USER_SCRIPTS_PATH}

# run all post-init.d scripts
. ${AYAQA_ON_BOOT_RUN_POST_INIT_SCRIPTS_PATH}

# Run supervisor without deamon
/usr/local/bin/supervisord -n -c /etc/supervisor/supervisord.conf