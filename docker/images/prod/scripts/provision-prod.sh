#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

# export term to fix tput issue
export TERM=xterm

. ${AYAQA_INFRA_LIBS_DIR}/liblog.sh