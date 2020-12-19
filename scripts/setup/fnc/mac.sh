#!/bin/bash

function install_brew() {
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

    if ! which brew >/dev/null; then
        log_error "Something went wrong with brew installing."
        exit 1
    fi
}

function install_from_brew_cask() {
    brew install $1 --cask
    if ! brew list --cask | grep -w -q $1; then
        log_error "Something went wrong with $1 installing."
        exit 1
    fi
}

function check_brew_cask() {
    for pkg in $1; do
        log "Checking ${pkg} is there."
        if ! which ${pkg} > /dev/null; then
            log_warn "Missing: Installing ${pkg} with brew cask."
            log_info "Password may be needed."

            install_from_brew_cask ${pkg}
        else
            log_ok "${pkg} is there."
        fi
    done
}

function install_from_brew() {
    brew install $1
    if ! brew list --formula | grep -w -q $1; then
        log_error "Something went wrong with $1 installing."
        exit 1
    fi
}

function check_brew() {
    for pkg in $1; do
        log "Checking ${pkg} is there."
        if ! which ${pkg} > /dev/null; then
            log_warn "Missing: Installing ${pkg} with brew."

            install_from_brew ${pkg}
        else
            log_ok "${pkg} is there."
        fi
    done
}