#!/bin/bash

function is_installed_apt()
{
    if dpkg -s $1 >/dev/null 2>&1; then
        true
    else
        false
    fi
}

function is_installed_which()
{
    if which $1 >/dev/null 2>&1; then
        true
    else
        false
    fi
}

function install_from_apt()
{
    sudo apt-get install -y $1
    if ! is_installed_apt $1; then
        log_error "Something went wrong with: $1"
        exit 1
    fi
}

function check_and_install_apt()
{
    for pkg in $1; do
        log "Checking ${pkg} if is installed."
        if ! is_installed_apt $pkg; then

            # for docker ce have to prepare env before install from apt
            prepare_for_docker_ce ${pkg}

            # packer also need some prepare before install it from apt
            prepare_for_packer ${pkg}

            log_warn "Missing... Installing ${pkg} with apt-get."
            install_from_apt ${pkg}
        else
            log_ok "${pkg} is there."
        fi
    done
}

function verify_binaries()
{
    for pkg in $1; do
        WHICH=$(which $pkg)
        if ! is_installed_which $pkg; then
            log_error "Cannot find binary path for: ${pkg}"
            
            exit 1;
        else
            log_ok "${pkg} is there in: ${CYAN_COLOR}${WHICH}${RESET_COLOR}"
        fi
    done
}

function prepare_for_docker_ce()
{
    if [[ "$1" == 'docker-ce' ]]; then
        log "Preparing $1 official repository."
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add –
        sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu  $(lsb_release -cs)  stable" 
        sudo apt-get update

        log_ok "$1 - Official repository added."
    fi
}

function prepare_for_packer()
{
    if [[ "$1" == 'packer' ]]; then
        log "Preparing $1 official repository."
        curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
        sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
        sudo apt-get update

        log_ok "$1 - Official repository added."
    fi
}