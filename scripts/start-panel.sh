#!/bin/bash

set -e

source "$(dirname "$0")/utils.sh"

PANEL_DIR="/opt/codex"

info "Starting Codex Panel..."

cd "$PANEL_DIR/backend"

if pm2 list | grep -q "codex-panel"; then
    pm2 delete codex-panel
fi

pm2 start dist/index.js \
    --name codex-panel

pm2 save

pm2 startup systemd -u root --hp /root >/tmp/pm2-startup.sh

bash /tmp/pm2-startup.sh || true

systemctl restart nginx

success "Codex Panel Started Successfully"

echo
pm2 status
echo
success "Panel URL: http://${PANEL_DOMAIN}"

if [[ "$ENABLE_SSL" =~ ^[Yy]$ ]]; then
    success "HTTPS URL: https://${PANEL_DOMAIN}"
fi