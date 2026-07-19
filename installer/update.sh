#!/bin/bash

set -e

source "$(dirname "$0")/scripts/utils.sh"

PANEL_DIR="/opt/codex"

info "Updating Codex Panel..."

cd "$PANEL_DIR"

info "Stopping Panel..."

pm2 stop codex-panel || true

########################################
# Backend
########################################

info "Updating Backend..."

cd backend

npm install

npx prisma generate

npx prisma migrate deploy

npm run build

########################################
# Frontend
########################################

cd ../frontend

info "Updating Frontend..."

npm install

npm run build

########################################
# Restart
########################################

pm2 restart codex-panel

systemctl restart nginx

success "Codex Panel Updated Successfully!"

pm2 status