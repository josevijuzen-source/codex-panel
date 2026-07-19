#!/bin/bash

set -e

source "$(dirname "$0")/utils.sh"

info "Running System Checks..."

########################################
# Root Check
########################################

if [[ $EUID -ne 0 ]]; then
    error "Please run this installer as root."
    exit 1
fi

########################################
# OS Check
########################################

if ! grep -qi "ubuntu" /etc/os-release; then
    error "Only Ubuntu 22.04/24.04 is supported."
    exit 1
fi

########################################
# Ubuntu Version
########################################

VERSION=$(. /etc/os-release && echo "$VERSION_ID")

case "$VERSION" in
    22.04|24.04)
        success "Ubuntu $VERSION detected."
        ;;
    *)
        error "Ubuntu $VERSION is not supported."
        exit 1
        ;;
esac

########################################
# CPU Check
########################################

CPU=$(nproc)

if [[ $CPU -lt 2 ]]; then
    warning "Only $CPU CPU core detected."
else
    success "CPU Check Passed ($CPU Cores)"
fi

########################################
# RAM Check
########################################

RAM=$(free -m | awk '/Mem:/ {print $2}')

if [[ $RAM -lt 2048 ]]; then
    warning "Only ${RAM}MB RAM detected."
else
    success "RAM Check Passed (${RAM}MB)"
fi

########################################
# Disk Check
########################################

DISK=$(df -BG / | awk 'NR==2 {gsub("G","",$4); print $4}')

if [[ $DISK -lt 10 ]]; then
    warning "Only ${DISK}GB free disk space."
else
    success "Disk Check Passed (${DISK}GB Free)"
fi

########################################
# Internet Check
########################################

if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
    success "Internet Connection OK"
else
    error "No internet connection."
    exit 1
fi

########################################
# Required Commands
########################################

for cmd in curl wget tar unzip systemctl; do
    if command -v "$cmd" >/dev/null 2>&1; then
        success "$cmd Found"
    else
        warning "$cmd Missing"
    fi
done

########################################
# Finish
########################################

success "All System Checks Passed"