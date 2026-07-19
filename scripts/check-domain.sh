#!/bin/bash

set -e

source "$(dirname "$0")/utils.sh"

info "Checking Domain..."

########################################
# Domain Empty
########################################

if [[ -z "$PANEL_DOMAIN" ]]; then
    error "Panel domain is empty."
    exit 1
fi

########################################
# Install dig
########################################

if ! command -v dig >/dev/null 2>&1; then
    info "Installing DNS utilities..."
    apt-get update -y
    apt-get install -y dnsutils
fi

########################################
# Validate Domain
########################################

if ! [[ "$PANEL_DOMAIN" =~ ^([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}$ ]]; then
    error "Invalid domain name."
    exit 1
fi

########################################
# Resolve Domain
########################################

DOMAIN_IP=$(dig +short A "$PANEL_DOMAIN" | tail -n1)

if [[ -z "$DOMAIN_IP" ]]; then
    warning "Domain does not resolve."
    warning "SSL installation may fail until DNS propagation is complete."
    exit 0
fi

success "Domain resolves to $DOMAIN_IP"

########################################
# Get Server Public IP
########################################

SERVER_IP=$(curl -4 -s https://api.ipify.org || true)

if [[ -n "$SERVER_IP" ]]; then

    info "Server IP : $SERVER_IP"

    if [[ "$DOMAIN_IP" == "$SERVER_IP" ]]; then
        success "Domain correctly points to this VPS."
    else
        warning "Domain does not point to this VPS."
        warning "SSL may fail until the DNS A record is updated."
    fi

fi

success "Domain Check Completed"