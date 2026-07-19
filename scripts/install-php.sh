#!/bin/bash

set -e

source "$(dirname "$0")/utils.sh"

info "Installing PHP 8.3..."

export DEBIAN_FRONTEND=noninteractive

apt update -y

apt install -y \
php-fpm \
php-cli \
php-common \
php-mysql \
php-curl \
php-mbstring \
php-xml \
php-zip \
php-gd \
php-bcmath \
php-intl \
php-soap \
php-opcache \
php-readline

systemctl enable php8.3-fpm || true
systemctl restart php8.3-fpm || true

success "PHP Installed Successfully"
success "Version: $(php -v | head -n 1)"