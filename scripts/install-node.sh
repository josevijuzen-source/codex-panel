#!/bin/bash

set -e

source "$(dirname "$0")/utils.sh"

info "Installing Node.js 22 LTS..."

export DEBIAN_FRONTEND=noninteractive

apt update -y

apt install -y \
curl \
ca-certificates \
gnupg \
software-properties-common

curl -fsSL https://deb.nodesource.com/setup_22.x | bash -

apt install -y nodejs

info "Installing PM2..."

npm install -g pm2

success "Node.js Version : $(node -v)"
success "NPM Version     : $(npm -v)"
success "PM2 Version     : $(pm2 -v)"