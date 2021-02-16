#!/bin/bash

# That file was built by example from bitnami/minideb-extras-base.
# Full link: https://github.com/bitnami/minideb-extras-base/blob/master/stretch/rootfs/liblog.sh

# Colors constants
RED_COLOR=${RED_COLOR:-$(tput setaf 1)}
GREEN_COLOR=${GREEN_COLOR:-$(tput setaf 2)}
YELLOW_COLOR=${YELLOW_COLOR:-$(tput setaf 3)}
CYAN_COLOR=${CYAN_COLOR:-$(tput setaf 6)}
MAGENTA_COLOR=${MAGENTA_COLOR:-$(tput setaf 5)}
RESET_COLOR=${RESET_COLOR:-$(tput sgr0)}

# Strings constants
OK_STRING="${GREEN_COLOR}[OK]${RESET_COLOR}"
ERROR_STRING="${RED_COLOR}[ERROR]${RESET_COLOR}"
WARN_STRING="${YELLOW_COLOR}[WARNING]${RESET_COLOR}"

########################
# Print to STDERR
# Arguments:
#   Message to print
# Returns:
#   None
#########################
stderr_print() {
    printf "%b\\n" "${*}" >&2
}
declare -f -x stderr_print

########################
# Log message
# Arguments:
#   Message to log
# Returns:
#   None
#########################
log() {
    echo -e "${CYAN_COLOR}${MODULE:-} ${MAGENTA_COLOR}$(date "+%T.%2N ")${RESET_COLOR} ${*}"
}
declare -f -x log

########################
# Log an 'info' message
# Arguments:
#   Message to log
# Returns:
#   None
#########################
info() {
    log "${CYAN_COLOR}INFO ${RESET_COLOR} ==> ${*}"
}
declare -f -x info

########################
# Log message
# Arguments:
#   Message to log
# Returns:
#   None
#########################
warn() {
    log "${YELLOW_COLOR}WARN ${RESET_COLOR} ==> ${*}"
}
declare -f -x warn

########################
# Log an 'error' message
# Arguments:
#   Message to log
# Returns:
#   None
#########################
error() {
    log "${RED_COLOR}ERROR${RESET_COLOR} ==> ${*}"
}
declare -f -x error

##############################
# Log a 'ok' prefixed message
# Arguments:
#   Message to log
# Returns:
#   None
##############################
log_ok() {
    log "${OK_STRING} ==> ${*}"
}
declare -f -x log_ok

################################
# Log a 'error' prefixed message
# Arguments:
#   Message to log
# Returns:
#   None
###############################
log_error() {
    log "${ERROR_STRING} ==> ${*}"
}
declare -f -x log_error

################################
# Log a 'warn' prefixed message
# Arguments:
#   Message to log
# Returns:
#   None
###############################
log_warn() {
    log "${WARN_STRING} ==> ${*}"
}
declare -f -x log_warn

########################
# Log a 'debug' message
# Globals:
#   AYAQA_DEBUG
# Arguments:
#   None
# Returns:
#   None
#########################
debug() {
    if [[ "${AYAQA_DEBUG:-false}" = true ]]; then
	log "${MAGENTA_COLOR}DEBUG${RESET_COLOR} ==> ${*}"
    fi
}

declare -f -x debug