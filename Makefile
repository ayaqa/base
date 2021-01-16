# Set default values
####################
SHELL              := /bin/bash
BUILD_TAG          ?= NULL
BUILD_ENABLE_DEBUG ?= false
IMAGE_NAME         ?= base

RESET_COLOR=$$(tput sgr0)
GREEN_COLOR=$$(tput setaf 2)
RED_COLOR=$$(tput setaf 1)
YELLOW_COLOR=$$(tput setaf 3)
CYAN_COLOR=$$(tput setaf 6)

OK_STRING=$(GREEN_COLOR)[OK]$(RESET_COLOR)
ERROR_STRING=$(RED_COLOR)[ERROR]$(RESET_COLOR)
WARN_STRING=$(YELLOW_COLOR)[WARNING]$(RESET_COLOR)
INFO_STRING=$(CYAN_COLOR)[INFO]$(RESET_COLOR)

LOCAL_REGISTRY="localhost:5001"

ROOT_INFRA_DIR=${CURDIR}
include vars.mk

IMAGE_FORMATTED_FOR_PRINT=$(RED_COLOR)[$(GREEN_COLOR)${IMAGE_NAME}$(RED_COLOR)]$(RESET_COLOR)

IMAGE_BUILD_ROOT_DIR=${IMAGES_BASE_DIR}/${IMAGE_NAME}
PROVISION_CONFIG_DIR=${IMAGE_BUILD_ROOT_DIR}/provision

# IMAGE_NAME based paths to build & vars
PACKER_BUILD_MANIFEST_FILE_NAME=build_manifest.json
PACKER_BUILD_MANIFEST_FILE_PATH=${IMAGE_BUILD_ROOT_DIR}/${PACKER_BUILD_MANIFEST_FILE_NAME}

PACKER_BUILD_VARS_FILE_NAME=build_vars.json
PACKER_BUILD_VARS_FILE_PATH=${IMAGE_BUILD_ROOT_DIR}/${PACKER_BUILD_VARS_FILE_NAME}

PACKER_BUILD_VARS_DYNAMIC_FILE_NAME=build_vars_dynamic.json
PACKER_BUILD_VARS_DYNAMIC_FILE_PATH=${IMAGE_BUILD_ROOT_DIR}/${PACKER_BUILD_VARS_DYNAMIC_FILE_NAME}

PACKER_BUILD_PROVISION_SCRIPTS_DIR=${IMAGE_BUILD_ROOT_DIR}/scripts

# Configurations parsed.
PACKER_VARS=$$(jq -s ".[0] * .[1] * .[2].AYAQA_BUILD_VARS.${IMAGE_NAME}" ${SHARED_VARS_FILE_PATH} ${PACKER_VARS_FILE_PATH} ${CONFIG_JSON_GENERATED_FILE_PATH})
PROVISION_VARS=$$(jq -s ".[0] * .[1] * .[2].AYAQA_PROVISION_VARS.${IMAGE_NAME}" ${SHARED_VARS_FILE_PATH} ${PROVISION_VARS_FILE_PATH} ${CONFIG_JSON_GENERATED_FILE_PATH})

.PHONY: help clear build_local pre_build_local compile_configs compile_dynamic_config validate_packer_build

# Aliases
#########
help: .display_help
clear: .clear_after_build_local
validate_local: .validate_packer_build
build_local: pre_build_local .build_local clear
pre_build_local: compile_configs
compile_dynamic_config: .compile_config_file
compile_configs: .continue_if_image_dir_is_fine compile_dynamic_config .compile_packer_dynamic_env .compile_provision_dynamic_env

# Helpers
#########
.display_help:
	@echo "";
	@echo -e "Usage example:\t make [TASK] [VARIABLES]";
	@echo -e "\t\t make display_config \t\t\t\t- display ${CONFIG_JSON_GENERATED_FILE_NAME} configuration file.";
	@echo -e "\t\t make compile_dynamic_config \t\t\t- compile ${CONFIG_JSON_GENERATED_FILE_NAME} using static and local if exists.";
	@echo -e "\t\t make compile_configs \t\t\t\t- compile configs and build dynamic envs.";
	@echo -e "\t\t make validate_local IMAGE_NAME=<image folder> \t- validate packer build file.";
	@echo -e "\t\t make build_local IMAGE_NAME=<image folder> \t- build image using packer.";
	@echo -e "\t\t make clear \t\t\t\t\t- clear all generated files.";

display_config: .compile_config_file
	@echo "${INFO_STRING} Raw output of ${CONFIG_JSON_GENERATED_FILE_NAME}"
	@cat ${CONFIG_JSON_GENERATED_FILE_PATH}

.continue_if_image_dir_is_fine:
	@if [[ ! -d "${IMAGE_BUILD_ROOT_DIR}" ]]; then \
		echo "${ERROR_STRING} ${IMAGE_FORMATTED_FOR_PRINT} image dir was not found."; \
		exit 1; \
	fi;
	@if [[ ! -f "${PACKER_BUILD_MANIFEST_FILE_PATH}" ]]; then \
		echo "${ERROR_STRING} ${PACKER_BUILD_MANIFEST_FILE_NAME} build manifest was not found at ${PACKER_BUILD_MANIFEST_FILE_PATH}"; \
		exit 1; \
	fi;
	@if [[ ! -f "${PACKER_BUILD_VARS_FILE_PATH}" ]]; then \
		echo "${ERROR_STRING} ${PACKER_BUILD_VARS_DYNAMIC_FILE_NAME} build vars was not found at ${PACKER_BUILD_VARS_FILE_PATH}"; \
		exit 1; \
	fi;
	@if [[ ! -d "${PROVISION_CONFIG_DIR}" ]]; then \
		echo "${ERROR_STRING} ${PROVISION_CONFIG_DIR} provision dir was not found."; \
		exit 1; \
	fi;
	@if [[ ! -d "${PACKER_BUILD_PROVISION_SCRIPTS_DIR}" ]]; then \
		echo "${ERROR_STRING} ${PACKER_BUILD_PROVISION_SCRIPTS_DIR} scripts dir was not found."; \
		exit 1; \
	fi;

# Build
#######
.compile_config_file:
	@echo "${INFO_STRING} Compile config file using static [${CONFIG_JSON_MAIN_FILE_NAME}] and local [${CONFIG_JSON_LOCAL_FILE_NAME}]."
	@echo "${WARN_STRING} If local config is found, both will be merged and all defined keys from local will override static ones."
	@if [[ -f "${CONFIG_JSON_LOCAL_FILE_PATH}" ]]; then \
		jq -s '.[0] * .[1]' ${CONFIG_JSON_MAIN_FILE_PATH} ${CONFIG_JSON_LOCAL_FILE_PATH} > ${CONFIG_JSON_GENERATED_FILE_PATH}; \
		echo "${OK_STRING} Local config ${CONFIG_JSON_LOCAL_FILE_NAME} overrides applied from ${CONFIG_JSON_LOCAL_FILE_PATH}"; \
	else \
		cat ${CONFIG_JSON_MAIN_FILE_PATH} > ${CONFIG_JSON_GENERATED_FILE_PATH}; \
		echo "${INFO_STRING} Local config overrides not found."; \
	fi;

.compile_packer_dynamic_env:
	@echo "${INFO_STRING} Generate dynamic env config for packer"
	@if [[ "${PACKER_VARS}" == "null" ]]; then echo '{}' > "${PACKER_BUILD_VARS_DYNAMIC_FILE_PATH}"; echo "${WARN_STRING} ${IMAGE_FORMATTED_FOR_PRINT} - No dynamic packer variables."; fi;
	@if [[ "${PACKER_VARS}" != "null" ]]; then jq -s '.[]' <<< "${PACKER_VARS}" > "${PACKER_BUILD_VARS_DYNAMIC_FILE_PATH}"; echo "${OK_STRING} ${IMAGE_FORMATTED_FOR_PRINT} - Dynamic packer vars file was generated."; fi;

.compile_provision_dynamic_env:
	@echo "${INFO_STRING} Generate dynamic env config for provision"
	@if [[ "${PROVISION_VARS}" == "null" ]]; then echo '{}' > "${PROVISION_VARS_DYNAMIC_FILE_PATH}"; echo "${WARN_STRING} ${IMAGE_FORMATTED_FOR_PRINT} - No dynamic provision variables."; fi;
	@if [[ "${PROVISION_VARS}" != "null" ]]; then jq -s '.[]' <<< "${PROVISION_VARS}" > "${PROVISION_VARS_DYNAMIC_FILE_PATH}"; echo "${OK_STRING} ${IMAGE_FORMATTED_FOR_PRINT} - Dynamic provision variable file was built."; fi;

.validate_packer_build: .continue_if_image_dir_is_fine .compile_packer_dynamic_env
	@echo "${INFO_STRING} Packer validate build manifest for IMAGE_NAME ${IMAGE_FORMATTED_FOR_PRINT}"
	@packer validate \
			-var-file=${PACKER_BUILD_VARS_FILE_PATH} \
			-var-file=${PACKER_BUILD_VARS_DYNAMIC_FILE_PATH} \
			-var BUILD_DIR="${IMAGE_BUILD_ROOT_DIR}" \
			-var SHARED_FS_DIR="${SHARED_FS_DIR}" \
		$$(if [[ "$(BUILD_TAG)" != "NULL" ]]; then echo "-var AYAQA_PROJECT_NAME=${LOCAL_REGISTRY}/$(IMAGE_NAME)"; echo "-var AYAQA_PROJECT_TAG=$(BUILD_TAG)"; fi;) \
	    $$(if [[ "$(BUILD_ENABLE_DEBUG)" == "true" ]]; then echo "-var AYAQA_PROJECT_DEBUG=\"true\""; fi;) \
	    "${PACKER_BUILD_MANIFEST_FILE_PATH}" || exit 1;

.build_local: validate_packer_build
	@echo "${INFO_STRING} Packer build for IMAGE_NAME ${IMAGE_FORMATTED_FOR_PRINT} [build local]"
	@packer build \
			-var-file=${PACKER_BUILD_VARS_FILE_PATH} \
			-var-file=${PACKER_BUILD_VARS_DYNAMIC_FILE_PATH} \
			-var BUILD_DIR="${IMAGE_BUILD_ROOT_DIR}" \
			-var SHARED_FS_DIR="${SHARED_FS_DIR}" \
		$$(if [[ "$(BUILD_TAG)" != "NULL" ]]; then echo "-var AYAQA_PROJECT_NAME=${LOCAL_REGISTRY}/$(IMAGE_NAME)"; echo "-var AYAQA_PROJECT_TAG=$(BUILD_TAG)"; fi;) \
	    $$(if [[ "$(BUILD_ENABLE_DEBUG)" == "true" ]]; then echo "-var AYAQA_PROJECT_DEBUG=\"true\""; fi;) \
			-timestamp-ui \
	    	"${PACKER_BUILD_MANIFEST_FILE_PATH}" || exit 1;

.clear_after_build_local:
	@echo "${INFO_STRING} Clean all dynamic files for ${IMAGE_FORMATTED_FOR_PRINT}."
	@rm -f "${PACKER_BUILD_VARS_DYNAMIC_FILE_PATH}"
	@rm -f "${PROVISION_VARS_DYNAMIC_FILE_PATH}"
	@rm -f "${CONFIG_JSON_GENERATED_FILE_PATH}"
	@echo "${OK_STRING} ${IMAGE_FORMATTED_FOR_PRINT} dynamics were cleared."