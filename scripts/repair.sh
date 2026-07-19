#!/bin/bash

set -e

source "$(dirname "$0")/utils.sh"

PANEL_DIR="/opt/codex"

info "Starting Codex Panel Repair..."

########################################
# Fix Permissions
########################################

info "Fixing Permissions..."

chown -R root:root "$PANEL_DIR"
chmod -R 755 "$PANEL_DIR"

mkdir -p /var/www
mkdir -p /var/log/codex
mkdir -p /var/backups/codex

########################################
# Backend
########################################

info "Rebuilding Backend..."

cd "$PANEL_DIR/backend"

npm install

npx prisma generate

npm run build

########################################
# Frontend
########################################

info "Rebuilding Frontend..."

cd "$PANEL_DIR/frontend"

npm install

npm run build

########################################
# Restart Services
########################################

info "Restarting Services..."

systemctl restart mariadb || true
systemctl restart nginx || true

pm2 restart codex-panel || pm2 start "$PANEL_DIR/backend/dist/index.js" --name codex-panel

pm2 save

########################################
# Nginx Test
########################################

nginx -t

########################################
# Done
########################################

success "Repair Completed Successfully!"

echo
pm2 status