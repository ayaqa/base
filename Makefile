SHELL              := /bin/bash
BUILD_TAG          ?= NULL
BUILD_WITH_DEBUG   ?= false
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

# Local registry host and port
LOCAL_REGISTRY="localhost:5001"
REMOTE_REGISTRY="ayaqa"

# Get Current dir
ROOT_INFRA_DIR=${CURDIR}
include ${ROOT_INFRA_DIR}/files/vars/make.mk

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

# Merge all vars from configs
# Order: static, packer or privision, config (config.json + local if exists), constants.json
PACKER_VARS=$$(jq -s ".[0] * .[1] * .[2].AYAQA_BUILD_VARS.${IMAGE_NAME} * .[3]" ${SHARED_VARS_FILE_PATH} ${PACKER_VARS_FILE_PATH} ${CONFIG_JSON_GENERATED_FILE_PATH} ${CONSTANTS_FILE_PATH})
PROVISION_VARS=$$(jq -s ".[0] * .[1] * .[2].AYAQA_PROVISION_VARS.${IMAGE_NAME} * .[3]" ${SHARED_VARS_FILE_PATH} ${PROVISION_VARS_FILE_PATH} ${CONFIG_JSON_GENERATED_FILE_PATH} ${CONSTANTS_FILE_PATH})

BUILT_IMAGE_NAME=$$(jq -sr ".[0].AYAQA_BUILD_VARS.${IMAGE_NAME}.AYAQA_INFRA_IMAGE_NAME" ${CONFIG_JSON_GENERATED_FILE_PATH})
BUILT_IMAGE_TAG=$$(jq -sr ".[0].AYAQA_BUILD_VARS.${IMAGE_NAME}.AYAQA_INFRA_IMAGE_TAG" ${CONFIG_JSON_GENERATED_FILE_PATH})
BUILT_IMAGE_TAG_AS_LATEST=$$(jq -sr ".[0].AYAQA_BUILD_VARS.${IMAGE_NAME}.AYAQA_INFRA_IMAGE_TAG_AS_LATEST" ${CONFIG_JSON_GENERATED_FILE_PATH})

.PHONY: help clear build_local pre_build compile_configs compile_dynamic_config validate_packer_build

LOG_FILE_DATE=$(shell date '+%d-%m-%y')
LOG_FILE_NAME=${IMAGE_NAME}-${LOG_FILE_DATE}.log
LOG_OUTPUT_PATH=logs/${LOG_FILE_NAME}

# Aliases
#########
help: .display_help
clear: .clear_after_build_local
validate_local: .validate_packer_build
build_local: pre_build .build_image .tag_local .push_local clear
build_remote: pre_build .build_image .tag_hub .push_hub clear
pre_build: compile_configs
compile_dynamic_config: .compile_config_file
compile_configs: .continue_if_image_dir_is_fine compile_dynamic_config .compile_packer_dynamic_env .compile_provision_dynamic_env

# Helpers targets
#################
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
	@echo "${INFO_STRING} Check if all files and dirs are fine."
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

.continue_if_image_tags_are_set:
	@echo "${INFO_STRING} Check if built image name and tag are configured."
	@if [[ "${BUILT_IMAGE_NAME}" == "null" ]]; then \
		echo "${ERROR_STRING} AYAQA_INFRA_IMAGE_NAME is not set for ${IMAGE_FORMATTED_FOR_PRINT} in ${CONFIG_JSON_GENERATED_FILE_NAME}."; \
		exit 1; \
	fi;

	@if [[ "${BUILT_IMAGE_TAG}" == "null" ]]; then \
		echo "${ERROR_STRING} BUILT_IMAGE_TAG is not set for ${IMAGE_FORMATTED_FOR_PRINT} in ${CONFIG_JSON_GENERATED_FILE_NAME}."; \
		exit 1; \
	fi;

# Build targets
################
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
	    $$(if [[ "$(BUILD_WITH_DEBUG)" == "true" ]]; then echo "-var AYAQA_INFRA_DEBUG=\"true\""; fi;) \
	    "${PACKER_BUILD_MANIFEST_FILE_PATH}";

.build_image: validate_packer_build
	@echo "${INFO_STRING} Packer build for IMAGE_NAME ${IMAGE_FORMATTED_FOR_PRINT}"
	@echo "${INFO_STRING} Output for ${IMAGE_FORMATTED_FOR_PRINT} will be saved: ${LOG_OUTPUT_PATH}"
	@packer build \
			-var-file=${PACKER_BUILD_VARS_FILE_PATH} \
			-var-file=${PACKER_BUILD_VARS_DYNAMIC_FILE_PATH} \
			-var BUILD_DIR="${IMAGE_BUILD_ROOT_DIR}" \
			-var SHARED_FS_DIR="${SHARED_FS_DIR}" \
	    $$(if [[ "$(BUILD_WITH_DEBUG)" == "true" ]]; then echo "-var AYAQA_INFRA_DEBUG=\"true\""; fi;) \
			-timestamp-ui \
	    	"${PACKER_BUILD_MANIFEST_FILE_PATH}" | tee ${LOG_OUTPUT_PATH} 2>&1;

.tag_local: .continue_if_image_tags_are_set
	@echo "${WARN_STRING} Local registry is running at ${LOCAL_REGISTRY}"
	@echo "${INFO_STRING} Tagging image as: ${BUILT_IMAGE_NAME}:${BUILT_IMAGE_TAG}"
	@docker tag ${BUILT_IMAGE_NAME}:latest ${LOCAL_REGISTRY}/${BUILT_IMAGE_NAME}:${BUILT_IMAGE_TAG}

	@if [[ "${BUILT_IMAGE_TAG}" != "latest" && "${BUILT_IMAGE_TAG_AS_LATEST}" == "true" ]]; then \
		echo "${WARN_STRING} Tagging image as ${BUILT_IMAGE_NAME}:latest"; \
		docker tag ${BUILT_IMAGE_NAME}:latest ${LOCAL_REGISTRY}/${BUILT_IMAGE_NAME}:latest; \
	fi;

.tag_hub: .continue_if_image_tags_are_set
	@echo "${WARN_STRING} Image will be tagged for Docker Hub: ${REMOTE_REGISTRY}"
	@echo "${INFO_STRING} Tagging image as: ${BUILT_IMAGE_NAME}:${BUILT_IMAGE_TAG}"
	@docker tag ${BUILT_IMAGE_NAME}:latest ${REMOTE_REGISTRY}/${BUILT_IMAGE_NAME}:${BUILT_IMAGE_TAG}

	@if [[ "${BUILT_IMAGE_TAG}" != "latest" && "${BUILT_IMAGE_TAG_AS_LATEST}" == "true" ]]; then \
		echo "${WARN_STRING} Tagging image as ${BUILT_IMAGE_NAME}:latest"; \
		docker tag ${BUILT_IMAGE_NAME}:latest ${REMOTE_REGISTRY}/${BUILT_IMAGE_NAME}:latest; \
	fi;

.push_local: .continue_if_image_tags_are_set
	@echo "${INFO_STRING} Push image ${BUILT_IMAGE_NAME}:${BUILT_IMAGE_TAG} to ${LOCAL_REGISTRY}"
	@docker push ${LOCAL_REGISTRY}/${BUILT_IMAGE_NAME}:${BUILT_IMAGE_TAG}

	@if [[ "${BUILT_IMAGE_TAG}" != "latest" && "${BUILT_IMAGE_TAG_AS_LATEST}" == "true" ]]; then \
		echo "${WARN_STRING} Push image ${BUILT_IMAGE_NAME}:latest to ${LOCAL_REGISTRY}"; \
		docker push ${LOCAL_REGISTRY}/${BUILT_IMAGE_NAME}:latest; \
	fi;

.push_hub: .continue_if_image_tags_are_set
	@echo "${WARN_STRING} Image will be pushed to Docker Hub: ${REMOTE_REGISTRY}"
	@echo "${INFO_STRING} Push image ${BUILT_IMAGE_NAME}:${BUILT_IMAGE_TAG} to ${REMOTE_REGISTRY}"
	@docker push ${REMOTE_REGISTRY}/${BUILT_IMAGE_NAME}:${BUILT_IMAGE_TAG}

	@if [[ "${BUILT_IMAGE_TAG}" != "latest" && "${BUILT_IMAGE_TAG_AS_LATEST}" == "true" ]]; then \
		echo "${WARN_STRING} Push image ${BUILT_IMAGE_NAME}:latest to ${REMOTE_REGISTRY}"; \
		docker push ${REMOTE_REGISTRY}/${BUILT_IMAGE_NAME}:latest; \
	fi;

.clear_after_build_local:
	@echo "${INFO_STRING} Clean all dynamic files for ${IMAGE_FORMATTED_FOR_PRINT}."
	@rm -f "${PACKER_BUILD_VARS_DYNAMIC_FILE_PATH}"
	@rm -f "${PROVISION_VARS_DYNAMIC_FILE_PATH}"
	@rm -f "${CONFIG_JSON_GENERATED_FILE_PATH}"
	@echo "${OK_STRING} ${IMAGE_FORMATTED_FOR_PRINT} dynamics were cleared."