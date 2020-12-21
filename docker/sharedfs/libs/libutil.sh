#!/bin/bash

function yes_or_exit()
{
    warn "${1:?missing argument}"

    while true; do
        read -p "Are you sure? [yes/no] " yn
        case $yn in
            [Yy]* ) break;;
            [Nn]* ) exit;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}

declare -f -x yes_or_exit


function find_full_path()
{
    local BINARY=${1:?nothing}
    if which $BINARY >/dev/null 2>&1; then
        echo $(command -v $BINARY) 
    else
        log_error "Binary $BINARY was not found."
        exit 1;
    fi
}

declare -f -x find_full_path