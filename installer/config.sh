#!/bin/bash
# Codex Panel - Configuration Module
# This file contains all configuration variables for the installer

# Color definitions
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export CYAN='\033[0;36m'
export WHITE='\033[1;37m'
export NC='\033[0m' # No Color

# Installation paths
export INSTALL_DIR="/opt/codex-panel"
export BACKEND_DIR="$INSTALL_DIR/backend"
export FRONTEND_DIR="$INSTALL_DIR/frontend"
export NGINX_SITES_AVAILABLE="/etc/nginx/sites-available"
export NGINX_SITES_ENABLED="/etc/nginx/sites-enabled"
export LOG_DIR="/var/log/codexpanel"
export LOG_FILE="/var/log/codexpanel-install.log"

# Application configuration
export APP_NAME="Codex Panel"
export APP_PORT="3000"
export APP_ENV="production"

# Database configuration
export DB_NAME="codexpanel"
export DB_USER="codexpanel"
export DB_PASSWORD=$(openssl rand -base64 32)
export DB_HOST="localhost"
export DB_PORT="3306"

# Redis configuration
export REDIS_HOST="localhost"
export REDIS_PORT="6379"

# Node.js configuration
export NODE_VERSION="20"
export NPM_VERSION="10"

# Nginx configuration
export NGINX_USER="www-data"
export NGINX_GROUP="www-data"

# SSL configuration
export SSL_EMAIL="admin@example.com"
export SSL_DIR="/etc/letsencrypt/live"

# Service configuration
export SERVICE_NAME="codexpanel"
export SERVICE_USER="www-data"
export SERVICE_GROUP="www-data"

# Installation options (will be set during installation)
export PANEL_DOMAIN=""
export ADMIN_EMAIL=""
export ADMIN_USERNAME=""
export ADMIN_PASSWORD=""
export INSTALL_MARIADB="Y"
export INSTALL_REDIS="Y"
export INSTALL_NGINX="Y"
export INSTALL_SSL="Y"

# Function to validate configuration
validate_config() {
    if [[ -z "$PANEL_DOMAIN" ]]; then
        echo -e "${RED}PANEL_DOMAIN is not set${NC}"
        return 1
    fi
    
    if [[ -z "$ADMIN_EMAIL" ]]; then
        echo -e "${RED}ADMIN_EMAIL is not set${NC}"
        return 1
    fi
    
    if [[ -z "$ADMIN_USERNAME" ]]; then
        echo -e "${RED}ADMIN_USERNAME is not set${NC}"
        return 1
    fi
    
    if [[ -z "$ADMIN_PASSWORD" ]]; then
        echo -e "${RED}ADMIN_PASSWORD is not set${NC}"
        return 1
    fi
    
    return 0
}