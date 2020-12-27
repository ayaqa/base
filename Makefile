# Set default values
####################
SHELL 			   := /bin/bash
BUILD_TAG          ?= NULL
BUILD_ENABLE_DEBUG ?= false
IMAGE_NAME         ?= base

RESET_COLOR=$$(tput sgr0)
GREEN_COLOR=$$(tput setaf 2)
RED_COLOR=$$(tput setaf 1)
YELLOW_COLOR=$$(tput setaf 3)
CYAN_COLOR=$$(tput setaf 6)

OK_STRING=$(GREEN_COLOR)[OK]$(RESET_COLOR)
ERROR_STRING=$(RED_COLOR)[ERRORS]$(RESET_COLOR)
WARN_STRING=$(YELLOW_COLOR)[WARNING]$(RESET_COLOR)
INFO_STRING=$(CYAN_COLOR)[INFO]$(RESET_COLOR)

LOCAL_REGISTRY="localhost:5001"

# Dirs
######
BASE_DIR=.
DOCKER_BASE_DIR=docker
IMAGES_BASE_DIR=${DOCKER_BASE_DIR}/images
SHARED_LIBS_DIR=${DOCKER_BASE_DIR}/sharedfs/libs/
COMMON_CONFIG_DIR=${DOCKER_BASE_DIR}/configs

IMAGE_BUILD_ROOT_DIR=${IMAGES_BASE_DIR}/${IMAGE_NAME}

PROVISION_CONFIG_DIR=${IMAGE_BUILD_ROOT_DIR}/provision

# Files
#######
CONFIG_JSON_MAIN_FILE_PATH=${BASE_DIR}/config.json
CONFIG_JSON_LOCAL_FILE_PATH=${BASE_DIR}/config-local.json
CONFIG_JSON_GENERATED_FILE_PATH=${BASE_DIR}/config-generated.json

# Common paths to files
PACKER_VARS_FILE_PATH=${COMMON_CONFIG_DIR}/packer-only-vars.json
PROVISION_VARS_FILE_PATH=${COMMON_CONFIG_DIR}/provision-only-vars.json
PROVISION_VARS_DYNAMIC_FILE=${PROVISION_CONFIG_DIR}/provision_vars_dynamic.json
SHARED_VARS_FILE_PATH=${COMMON_CONFIG_DIR}/shared-vars.json

# IMAGE_NAME based paths to build & vars
PACKER_BUILD_MANIFEST_PATH=${IMAGE_BUILD_ROOT_DIR}/build_manifest.json
PACKER_BUILD_VARS_PATH=${IMAGE_BUILD_ROOT_DIR}/build_vars.json
PACKER_BUILD_VARS_DYNAMIC_FILE=${IMAGE_BUILD_ROOT_DIR}/build_vars_dynamic.json

# Configurations parsed.
PACKER_VARS=$$(jq -s ".[0] * .[1] * .[2].AYAQA_BUILD_VARS.${IMAGE_NAME}" ${SHARED_VARS_FILE_PATH} ${PACKER_VARS_FILE_PATH} ${CONFIG_JSON_GENERATED_FILE_PATH})
PROVISION_VARS=$$(jq -s ".[0] * .[1] * .[2].AYAQA_PROVISION_VARS.${IMAGE_NAME}" ${SHARED_VARS_FILE_PATH} ${PROVISION_VARS_FILE_PATH} ${CONFIG_JSON_GENERATED_FILE_PATH})

# Aliases
#########
help: display_help
build_local: pre_build_local __build_local clear_after_build_local
pre_build_local: compile_configs
compile_configs: continue_if_image_dir_is_fine compile_config_file compile_packer_dynamic_env compile_provision_dynamic_env

# Helpers
#########
display_help:
	@echo "";
	@echo -e "Usage example:\t make [TASK] [VARIABLES]";
	@echo -e "\t\t make display_config \t\t\t\t display configuration file.";

display_config: compile_config_file
	@echo "${INFO_STRING} Raw json configuration file"
	@cat ${CONFIG_JSON_GENERATED_FILE_PATH}

continue_if_image_dir_is_fine:
	@if [[ ! -d "${IMAGE_BUILD_ROOT_DIR}" ]]; then \
		echo "${ERROR_STRING} ${IMAGE_NAME} image dir was not found."; \
		exit 1; \
	fi;
	@if [[ ! -f "${PACKER_BUILD_MANIFEST_PATH}" ]]; then \
		echo "${ERROR_STRING} ${PACKER_BUILD_MANIFEST_PATH} was not found. "; \
		exit 1; \
	fi;
	@if [[ ! -f "${PACKER_BUILD_VARS_PATH}" ]]; then \
		echo "${ERROR_STRING} ${PACKER_BUILD_VARS_PATH} was not found. "; \
		exit 1; \
	fi;

# Build
#######
compile_config_file:
	@echo "${INFO_STRING} Compile config file using static [${CONFIG_JSON_MAIN_FILE_PATH}] and local [${CONFIG_JSON_LOCAL_FILE_PATH}]."
	@echo "${WARN_STRING} If local config is found, both will be merged and all defined keys from local will override static ones."
	@if [[ -f "${CONFIG_JSON_LOCAL_FILE_PATH}" ]]; then \
		jq -s '.[0] * .[1]' ${CONFIG_JSON_MAIN_FILE_PATH} ${CONFIG_JSON_LOCAL_FILE_PATH} > ${CONFIG_JSON_GENERATED_FILE_PATH}; \
		echo "${OK_STRING} Local config ${CONFIG_JSON_LOCAL_FILE_PATH} overrides applied."; \
	else \
		cat ${CONFIG_JSON_MAIN_FILE_PATH} > ${CONFIG_JSON_GENERATED_FILE_PATH}; \
		echo "${INFO_STRING} Local config overrides not found."; \
	fi;

compile_packer_dynamic_env:
	@echo "${INFO_STRING} Generate dynamic env config for packer"
	@if [[ "${PACKER_VARS}" == "null" ]]; then echo '{}' > "${PACKER_BUILD_VARS_DYNAMIC_FILE}"; echo "${WARN_STRING} ${IMAGE_NAME} - No dynamic packer variables."; fi;
	@if [[ "${PACKER_VARS}" != "null" ]]; then jq -s '.[]' <<< "${PACKER_VARS}" > "${PACKER_BUILD_VARS_DYNAMIC_FILE}"; echo "${OK_STRING} ${IMAGE_NAME} - Dynamic packer vars file was generated."; fi;

compile_provision_dynamic_env:
	@echo "${INFO_STRING} Generate dynamic env config for provision"
	@if [[ "${PROVISION_VARS}" == "null" ]]; then echo '{}' > "${PROVISION_VARS_DYNAMIC_FILE}"; echo "${WARN_STRING} ${IMAGE_NAME} - No dynamic provision variables."; fi;
	@if [[ "${PROVISION_VARS}" != "null" ]]; then jq -s '.[]' <<< "${PROVISION_VARS}" > "${PROVISION_VARS_DYNAMIC_FILE}"; echo "${OK_STRING} ${IMAGE_NAME} - Dynamic provision variable file was built."; fi;

validate_packer_build: continue_if_image_dir_is_fine compile_packer_dynamic_env
	@echo "${INFO_STRING} Packer validate build manifest for IMAGE_NAME=${YELLOW_COLOR}${IMAGE_NAME}${RESET_COLOR}"
	@packer validate \
			-var-file=${PACKER_BUILD_VARS_PATH} \
			-var-file=${PACKER_BUILD_VARS_DYNAMIC_FILE} \
			-var BUILD_DIR="${IMAGE_BUILD_ROOT_DIR}" \
			-var SHARED_LIBS_DIR="${SHARED_LIBS_DIR}" \
		$$(if [[ "$(BUILD_TAG)" != "NULL" ]]; then echo "-var AYAQA_PROJECT_NAME=${LOCAL_REGISTRY}/$(IMAGE_NAME)"; echo "-var AYAQA_PROJECT_TAG=$(BUILD_TAG)"; fi;) \
	    $$(if [[ "$(BUILD_ENABLE_DEBUG)" == "true" ]]; then echo "-var AYAQA_PROJECT_DEBUG=\"true\""; fi;) \
	    "${PACKER_BUILD_MANIFEST_PATH}" || exit 1;

__build_local: validate_packer_build
	@echo "${INFO_STRING} Packer build for IMAGE_NAME=${YELLOW_COLOR}${IMAGE_NAME}${RESET_COLOR} [build local]"
	@packer build \
			-var-file=${PACKER_BUILD_VARS_PATH} \
			-var-file=${PACKER_BUILD_VARS_DYNAMIC_FILE} \
			-var BUILD_DIR="${IMAGE_BUILD_ROOT_DIR}" \
			-var SHARED_LIBS_DIR="${SHARED_LIBS_DIR}" \
		$$(if [[ "$(BUILD_TAG)" != "NULL" ]]; then echo "-var AYAQA_PROJECT_NAME=${LOCAL_REGISTRY}/$(IMAGE_NAME)"; echo "-var AYAQA_PROJECT_TAG=$(BUILD_TAG)"; fi;) \
	    $$(if [[ "$(BUILD_ENABLE_DEBUG)" == "true" ]]; then echo "-var AYAQA_PROJECT_DEBUG=\"true\""; fi;) \
			-timestamp-ui \
	    	"${PACKER_BUILD_MANIFEST_PATH}" || exit 1;

clear_after_build_local: continue_if_image_dir_is_fine
	@echo "${INFO_STRING} Clean all dynamic files for ${YELLOW_COLOR}${IMAGE_NAME}${RESET_COLOR}."
	@rm -f "${PACKER_BUILD_VARS_DYNAMIC_FILE}"
	@echo "${OK_STRING} ${YELLOW_COLOR}${IMAGE_NAME}${RESET_COLOR} dynamics were cleared."