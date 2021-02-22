#!/bin/bash

set -x

CONFIG_LOCAL_PATH="config-local.json"
CONFIG_CI_PATH=${1:-"config-push-main.json"}

echo "Config file: ${CONFIG_CI_PATH}"

cp .github/files/${CONFIG_CI_PATH} ./${CONFIG_LOCAL_PATH}