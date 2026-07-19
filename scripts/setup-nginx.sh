#!/bin/bash

set -e

source "$(dirname "$0")/utils.sh"

info "Configuring Nginx..."

cat > /etc/nginx/sites-available/codex <<EOF
server {
    listen 80;
    server_name ${PANEL_DOMAIN};

    client_max_body_size 500M;

    location / {
        proxy_pass http://127.0.0.1:5000;

        proxy_http_version 1.1;

        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;

        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
EOF

ln -sf /etc/nginx/sites-available/codex /etc/nginx/sites-enabled/codex

rm -f /etc/nginx/sites-enabled/default

nginx -t

systemctl restart nginx

success "Nginx configured successfully."

if [[ "$ENABLE_SSL" =~ ^[Yy]$ ]]; then
    info "Generating SSL certificate..."

    certbot --nginx \
        -d "$PANEL_DOMAIN" \
        --non-interactive \
        --agree-tos \
        -m "$ADMIN_EMAIL" \
        --redirect

    success "SSL Installed Successfully"
fi