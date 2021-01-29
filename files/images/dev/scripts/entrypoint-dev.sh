#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

. ${AYAQA_INFRA_LIBS_DIR}/liblog.sh
. ${AYAQA_INFRA_LIBS_DIR}/libfs.sh

if is_file_exists ${AYAQA_INFRA_BOOT_SETUP_FILE_PATH}; then
    info "** Starting container setup **"
    chmod 700 ${AYAQA_INFRA_BOOT_SETUP_FILE_PATH}
    ${AYAQA_INFRA_BOOT_SETUP_FILE_PATH}
    info "** Container setup finished! **"
fi;

# Run supervisor without deamon
/usr/local/bin/supervisord -n -c /etc/supervisor/supervisord.conf