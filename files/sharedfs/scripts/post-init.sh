#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

. ${AYAQA_INFRA_LIBS_DIR}/liblog.sh

POST_INIT_FILE_PATH=${AYAQA_INFRA_DIR}/.post_init_initialized
if [[ ! -f "${POST_INIT_FILE_PATH}" && -d "${AYAQA_INFRA_ON_BOOT_BASH_SCRIPTS_POST_INIT}" ]]; then
    read -r -a init_scripts <<< "$(find "${AYAQA_INFRA_ON_BOOT_BASH_SCRIPTS_POST_INIT}" -name "*.sh" -type f -print0 | sort -z | xargs -0)"
    if [[ "${#init_scripts[@]}" -gt 0 ]] && [[ ! -f "${POST_INIT_FILE_PATH}" ]]; then
        warn "** Ensure post init scripts are executable. **"
        find "${AYAQA_INFRA_ON_BOOT_BASH_SCRIPTS_POST_INIT}" -name "*.sh" -print -exec chmod u+x {} +

        warn "** Execute post init scripts **"
        for init_script in "${init_scripts[@]}"; do
            info "** Executing: ${init_script} **"
            log "============== ${init_script} output start ========"
            bash ${init_script}
            log "============== ${init_script} output end ========"
        done
    fi

    touch ${POST_INIT_FILE_PATH}
fi

log_ok "Post init scripts are initialized."