#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

. ${AYAQA_INFRA_LIBS_DIR}/liblog.sh

USER_SCRIPTS_FILE_PATH=${AYAQA_INFRA_DIR}/.user_scripts_initialized
if [[ ! -f "${USER_SCRIPTS_FILE_PATH}" && -d "${AYAQA_INFRA_ON_BOOT_BASH_SCRIPTS_VOLUME}" ]]; then
    read -r -a init_scripts <<< "$(find "${AYAQA_INFRA_ON_BOOT_BASH_SCRIPTS_VOLUME}" -name "*.sh" -type f -print0 | xargs -0)"
    if [[ "${#init_scripts[@]}" -gt 0 ]] && [[ ! -f "${USER_SCRIPTS_FILE_PATH}" ]]; then
        warn "** Ensure scripts are executable **"
        find "${AYAQA_INFRA_ON_BOOT_BASH_SCRIPTS_VOLUME}" -name "*.sh" -print -exec chmod u+x {} +

        info "** Execute user scripts **"
        for init_script in "${init_scripts[@]}"; do
            info "** Execute: ${init_script} **"
            log "============== ${init_script} output start ========"
            bash ${init_script}
            log "============== ${init_script} output end ========"
        done
    fi

    touch ${USER_SCRIPTS_FILE_PATH}
fi

log_ok "User scripts are initialized."