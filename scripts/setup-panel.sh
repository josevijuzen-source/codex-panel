#!/bin/bash

set -e

source "$(dirname "$0")/utils.sh"

PANEL_DIR="/opt/codex"

info "Installing Codex Panel..."

mkdir -p "$PANEL_DIR"

info "Copying panel files..."

cp -r . "$PANEL_DIR"

cd "$PANEL_DIR"

####################################
# Backend
####################################

info "Installing backend..."

cd backend

npm install

npx prisma generate

npx prisma migrate deploy

npm run build

####################################
# Frontend
####################################

cd ../frontend

info "Installing frontend..."

npm install

npm run build

####################################
# Directories
####################################

mkdir -p /var/www
mkdir -p /var/log/codex
mkdir -p /var/backups/codex

####################################
# Environment
####################################

cd "$PANEL_DIR/backend"

cat > .env <<EOF
PORT=5000

DATABASE_URL="mysql://codex:${DB_PASSWORD}@localhost:3306/codex"

JWT_SECRET=$(openssl rand -hex 32)

ADMIN_USERNAME=${ADMIN_USERNAME}
ADMIN_PASSWORD=${ADMIN_PASSWORD}
ADMIN_EMAIL=${ADMIN_EMAIL}

PANEL_DOMAIN=${PANEL_DOMAIN}
EOF

success "Environment Created"

success "Codex Panel Installed Successfully"