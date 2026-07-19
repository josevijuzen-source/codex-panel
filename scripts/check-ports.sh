#!/bin/bash

set -e

source "$(dirname "$0")/utils.sh"

info "Checking Required Ports..."

########################################
# Port 80
########################################

if ss -tulpn | grep -q ":80 "; then
    error "Port 80 is already in use."
    ss -tulpn | grep ":80 "
    exit 1
else
    success "Port 80 Available"
fi

########################################
# Port 443
########################################

if ss -tulpn | grep -q ":443 "; then
    error "Port 443 is already in use."
    ss -tulpn | grep ":443 "
    exit 1
else
    success "Port 443 Available"
fi

########################################
# Port 5000 (Backend)
########################################

if ss -tulpn | grep -q ":5000 "; then
    warning "Port 5000 already in use."
else
    success "Port 5000 Available"
fi

success "Port Check Completed"