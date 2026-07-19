#!/bin/bash

set -e

source "$(dirname "$0")/config.sh"

clear

LOG_DIR="$(dirname "$0")/logs"
mkdir -p "$LOG_DIR"
touch "$LOG_DIR/install.log"

exec > >(tee -a "$LOG_DIR/install.log") 2>&1

echo "============================================================"
echo "               CODEX PANEL INSTALLER v1.0"
echo "============================================================"
echo

############################################
# Make Scripts Executable
############################################

chmod +x scripts/*.sh

############################################
# System Checks
############################################

echo "[0/9] Running Pre-Installation Checks..."

./scripts/precheck.sh
./scripts/check-ports.sh

echo

############################################
# User Configuration
############################################

read -rp "Panel Domain (panel.example.com): " PANEL_DOMAIN

read -rp "Administrator Email: " ADMIN_EMAIL

echo

read -rp "Enable HTTPS (Y/N): " ENABLE_SSL

echo

read -rsp "Database Password: " DB_PASSWORD
echo

read -rp "Administrator Username: " ADMIN_USERNAME

read -rsp "Administrator Password: " ADMIN_PASSWORD
echo

############################################
# Export Variables
############################################

export PANEL_DOMAIN
export ADMIN_EMAIL
export ENABLE_SSL
export DB_PASSWORD
export ADMIN_USERNAME
export ADMIN_PASSWORD

############################################
# Domain Check
############################################

echo
echo "[1/9] Checking Domain..."

./scripts/check-domain.sh

############################################
# Installation
############################################

echo
echo "[2/9] Installing Nginx..."
./scripts/install-nginx.sh

echo
echo "[3/9] Installing Node.js..."
./scripts/install-node.sh

echo
echo "[4/9] Installing PHP..."
./scripts/install-php.sh

echo
echo "[5/9] Installing MariaDB..."
./scripts/install-mariadb.sh

echo
echo "[6/9] Installing Codex Panel..."
./scripts/setup-panel.sh

echo
echo "[7/9] Configuring Nginx..."
./scripts/setup-nginx.sh

echo
echo "[8/9] Starting Codex Panel..."
./scripts/start-panel.sh

echo
echo "[9/9] Cleaning Temporary Files..."

apt autoremove -y >/dev/null 2>&1 || true
apt autoclean >/dev/null 2>&1 || true

############################################
# Finish
############################################

clear

echo "============================================================"
echo "          🎉 CODEX PANEL INSTALLED SUCCESSFULLY"
echo "============================================================"
echo

if [[ "$ENABLE_SSL" =~ ^[Yy]$ ]]; then
    PANEL_URL="https://${PANEL_DOMAIN}"
    SSL_STATUS="Enabled ✅"
else
    PANEL_URL="http://${PANEL_DOMAIN}"
    SSL_STATUS="Disabled ❌"
fi

echo "Panel Information"
echo "------------------------------------------------------------"
echo "URL        : $PANEL_URL"
echo "Username   : $ADMIN_USERNAME"
echo "Email      : $ADMIN_EMAIL"
echo "SSL        : $SSL_STATUS"
echo

echo "Installed Services"
echo "------------------------------------------------------------"
echo "✓ Nginx"
echo "✓ Node.js"
echo "✓ PHP"
echo "✓ MariaDB"
echo "✓ PM2"
echo "✓ Codex Panel"
echo

echo "Backend Service : codex-panel"

echo
echo "Installation Log"
echo "------------------------------------------------------------"
echo "$LOG_DIR/install.log"

echo
echo "============================================================"
echo "Thank you for installing Codex Panel ❤️"
echo "============================================================"