#!/bin/bash

set -e

source "$(dirname "$0")/scripts/utils.sh"

info "Removing Codex Panel..."

pm2 delete codex-panel || true

systemctl stop nginx || true

rm -rf /opt/codex

rm -f /etc/nginx/sites-enabled/codex
rm -f /etc/nginx/sites-available/codex

systemctl restart nginx || true

success "Codex Panel Uninstalled Successfully."