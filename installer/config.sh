#!/bin/bash

# Panel
PANEL_NAME="Codex Panel"
PANEL_USER="codex"
INSTALL_DIR="/opt/codex"

# Web
WEB_ROOT="/var/www"
NGINX_DIR="/etc/nginx"

# Ports
BACKEND_PORT=5000
FRONTEND_PORT=3000

# Runtime (filled by install.sh)
PANEL_DOMAIN=""
ADMIN_EMAIL=""
ENABLE_SSL=""
DB_NAME="codex"
DB_USER="codex"
DB_PASSWORD=""
ADMIN_USERNAME=""
ADMIN_PASSWORD=""
TIMEZONE="UTC"