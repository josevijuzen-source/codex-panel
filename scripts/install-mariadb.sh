#!/bin/bash

set -e

source "$(dirname "$0")/utils.sh"

info "Installing MariaDB..."

export DEBIAN_FRONTEND=noninteractive

apt update -y

apt install -y mariadb-server

systemctl enable mariadb
systemctl restart mariadb

success "MariaDB Installed"
success "Version: $(mysql --version)"

info "Creating Codex Panel Database..."

mysql <<EOF
CREATE DATABASE IF NOT EXISTS codex CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE USER IF NOT EXISTS 'codex'@'localhost'
IDENTIFIED BY '${DB_PASSWORD}';

GRANT ALL PRIVILEGES ON codex.* TO 'codex'@'localhost';

FLUSH PRIVILEGES;
EOF

success "Database Created Successfully"
success "Database Name : codex"
success "Database User : codex"