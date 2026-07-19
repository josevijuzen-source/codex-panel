#!/bin/bash

set -e

source "$(dirname "$0")/utils.sh"

info "Running Codex Panel Health Check..."

echo

########################################
# Nginx
########################################

if systemctl is-active --quiet nginx; then
    success "Nginx        : Running"
else
    error "Nginx        : Stopped"
fi

########################################
# MariaDB
########################################

if systemctl is-active --quiet mariadb; then
    success "MariaDB      : Running"
else
    error "MariaDB      : Stopped"
fi

########################################
# PM2
########################################

if command -v pm2 >/dev/null 2>&1; then
    success "PM2          : Installed"
else
    error "PM2          : Not Installed"
fi

########################################
# Codex Backend
########################################

if pm2 list | grep -q "codex-panel"; then
    success "Codex Panel  : Running"
else
    error "Codex Panel  : Offline"
fi

########################################
# Node.js
########################################

if command -v node >/dev/null 2>&1; then
    success "Node.js      : $(node -v)"
else
    error "Node.js      : Missing"
fi

########################################
# PHP
########################################

if command -v php >/dev/null 2>&1; then
    success "PHP          : $(php -r 'echo PHP_VERSION;')"
else
    error "PHP          : Missing"
fi

########################################
# Database
########################################

if mysqladmin ping >/dev/null 2>&1; then
    success "Database     : Connected"
else
    error "Database     : Connection Failed"
fi

########################################
# Disk Usage
########################################

echo
df -h /

########################################
# Memory
########################################

echo
free -h

########################################
# CPU Load
########################################

echo
uptime

echo
success "Health Check Completed"