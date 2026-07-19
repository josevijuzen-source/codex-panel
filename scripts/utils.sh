#!/bin/bash

# ==========================================
# Codex Panel Installer Utilities
# ==========================================

# Colors
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
NC="\033[0m"

# Print info
info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Print success
success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Print warning
warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Print error
error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# Check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        error "Please run this installer as root."
    fi
}

# Check Ubuntu version
check_ubuntu() {
    if ! grep -q "Ubuntu" /etc/os-release; then
        error "This installer only supports Ubuntu."
    fi

    VERSION=$(lsb_release -rs)

    if [ "$VERSION" != "24.04" ]; then
        error "Ubuntu 24.04 is required. Detected: $VERSION"
    fi

    success "Ubuntu 24.04 detected."
}

# Check internet
check_internet() {
    if ! ping -c 1 google.com >/dev/null 2>&1; then
        error "No internet connection."
    fi

    success "Internet connection OK."
}

# Run command
run() {
    info "$1"
    eval "$2"

    if [ $? -ne 0 ]; then
        error "Failed: $1"
    fi
}