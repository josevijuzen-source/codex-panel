#!/bin/bash

set -e

source "$(dirname "$0")/utils.sh"

info "Installing Nginx..."

export DEBIAN_FRONTEND=noninteractive

apt update -y

apt install -y \
nginx \
certbot \
python3-certbot-nginx

systemctl enable nginx
systemctl restart nginx

if command -v ufw >/dev/null 2>&1; then
    info "Configuring Firewall..."
    ufw allow 'Nginx Full' || true
    ufw allow OpenSSH || true
fi

systemctl is-active --quiet nginx

success "Nginx Installed Successfully"
success "Version: $(nginx -v 2>&1)"
success "Certbot Version: $(certbot --version)"