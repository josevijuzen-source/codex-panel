#!/bin/bash
# Codex Panel - Modular Installer Main Script
# This script orchestrates the entire installation process

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# Source all module files
source "$SCRIPT_DIR/config.sh"
source "$SCRIPT_DIR/functions.sh"
source "$SCRIPT_DIR/os.sh"
source "$SCRIPT_DIR/packages.sh"
source "$SCRIPT_DIR/database.sh"
source "$SCRIPT_DIR/node.sh"
source "$SCRIPT_DIR/frontend.sh"
source "$SCRIPT_DIR/backend.sh"
source "$SCRIPT_DIR/nginx.sh"
source "$SCRIPT_DIR/ssl.sh"
source "$SCRIPT_DIR/service.sh"
source "$SCRIPT_DIR/finish.sh"

# Function to display the installation header
display_header() {
    clear
    echo -e "${CYAN}======================================${NC}"
    echo -e "${WHITE}      CODEX PANEL INSTALLER${NC}"
    echo -e "${CYAN}======================================${NC}"
    echo ""
}

# Function to collect user input
collect_user_input() {
    echo -e "${YELLOW}Please provide the following information:${NC}"
    echo ""
    
    # Panel Domain
    read -p "Panel Domain (e.g., panel.example.com): " PANEL_DOMAIN
    while [[ -z "$PANEL_DOMAIN" ]]; do
        echo -e "${RED}Domain is required.${NC}"
        read -p "Panel Domain: " PANEL_DOMAIN
    done
    
    # Admin Email
    read -p "Admin Email: " ADMIN_EMAIL
    while [[ -z "$ADMIN_EMAIL" ]]; do
        echo -e "${RED}Email is required.${NC}"
        read -p "Admin Email: " ADMIN_EMAIL
    done
    
    # Admin Username
    read -p "Admin Username: " ADMIN_USERNAME
    while [[ -z "$ADMIN_USERNAME" ]]; do
        echo -e "${RED}Username is required.${NC}"
        read -p "Admin Username: " ADMIN_USERNAME
    done
    
    # Admin Password
    read -s -p "Admin Password: " ADMIN_PASSWORD
    echo ""
    while [[ ${#ADMIN_PASSWORD} -lt 8 ]]; do
        echo -e "${RED}Password must be at least 8 characters.${NC}"
        read -s -p "Admin Password: " ADMIN_PASSWORD
        echo ""
    done
    
    # Confirm password
    read -s -p "Confirm Admin Password: " ADMIN_PASSWORD_CONFIRM
    echo ""
    while [[ "$ADMIN_PASSWORD" != "$ADMIN_PASSWORD_CONFIRM" ]]; do
        echo -e "${RED}Passwords do not match.${NC}"
        read -s -p "Admin Password: " ADMIN_PASSWORD
        echo ""
        read -s -p "Confirm Admin Password: " ADMIN_PASSWORD_CONFIRM
        echo ""
    done
    
    echo ""
    
    # Optional components
    read -p "Install MariaDB? [Y/n]: " INSTALL_MARIADB
    INSTALL_MARIADB=${INSTALL_MARIADB:-Y}
    
    read -p "Install Redis? [Y/n]: " INSTALL_REDIS
    INSTALL_REDIS=${INSTALL_REDIS:-Y}
    
    read -p "Install Nginx? [Y/n]: " INSTALL_NGINX
    INSTALL_NGINX=${INSTALL_NGINX:-Y}
    
    read -p "Install SSL (Let's Encrypt)? [Y/n]: " INSTALL_SSL
    INSTALL_SSL=${INSTALL_SSL:-Y}
    
    echo ""
    
    # Save to config file for other modules
    cat > "$SCRIPT_DIR/.install.config" <<EOF
PANEL_DOMAIN="$PANEL_DOMAIN"
ADMIN_EMAIL="$ADMIN_EMAIL"
ADMIN_USERNAME="$ADMIN_USERNAME"
ADMIN_PASSWORD="$ADMIN_PASSWORD"
INSTALL_MARIADB="$INSTALL_MARIADB"
INSTALL_REDIS="$INSTALL_REDIS"
INSTALL_NGINX="$INSTALL_NGINX"
INSTALL_SSL="$INSTALL_SSL"
EOF
}

# Function to load config
load_config() {
    if [[ -f "$SCRIPT_DIR/.install.config" ]]; then
        source "$SCRIPT_DIR/.install.config"
    else
        echo -e "${RED}Configuration file not found.${NC}"
        exit 1
    fi
}

# Function to display installation progress
show_progress() {
    local step=$1
    local total=$2
    local message=$3
    local percent=$((step * 100 / total))
    
    echo -e "${CYAN}[${step}/${total}]${NC} ${message}"
}

# Main installation function
main_install() {
    local total_steps=12
    local current_step=0
    
    # Display header
    display_header
    
    # Collect user input
    collect_user_input
    load_config
    
    # Start installation
    echo -e "${GREEN}Starting installation...${NC}\n"
    
    # Step 1: OS Detection
    ((current_step++))
    show_progress $current_step $total_steps "Detecting operating system..."
    detect_os
    
    # Step 2: System Check
    ((current_step++))
    show_progress $current_step $total_steps "Checking system requirements..."
    check_system_requirements
    
    # Step 3: Update System
    ((current_step++))
    show_progress $current_step $total_steps "Updating system packages..."
    update_system
    
    # Step 4: Install Packages
    ((current_step++))
    show_progress $current_step $total_steps "Installing required packages..."
    install_required_packages
    
    # Step 5: Install Node.js
    ((current_step++))
    show_progress $current_step $total_steps "Installing Node.js LTS..."
    install_nodejs
    
    # Step 6: Install Database
    if [[ "$INSTALL_MARIADB" == "Y" ]] || [[ "$INSTALL_MARIADB" == "y" ]]; then
        ((current_step++))
        show_progress $current_step $total_steps "Installing MariaDB..."
        install_mariadb
    else
        ((current_step++))
        echo -e "${YELLOW}[${current_step}/${total_steps}] Skipping MariaDB installation${NC}"
    fi
    
    # Step 7: Install Redis
    if [[ "$INSTALL_REDIS" == "Y" ]] || [[ "$INSTALL_REDIS" == "y" ]]; then
        ((current_step++))
        show_progress $current_step $total_steps "Installing Redis..."
        install_redis
    else
        ((current_step++))
        echo -e "${YELLOW}[${current_step}/${total_steps}] Skipping Redis installation${NC}"
    fi
    
    # Step 8: Setup Backend
    ((current_step++))
    show_progress $current_step $total_steps "Setting up backend..."
    setup_backend
    
    # Step 9: Setup Frontend
    ((current_step++))
    show_progress $current_step $total_steps "Setting up frontend..."
    setup_frontend
    
    # Step 10: Configure Nginx
    if [[ "$INSTALL_NGINX" == "Y" ]] || [[ "$INSTALL_NGINX" == "y" ]]; then
        ((current_step++))
        show_progress $current_step $total_steps "Configuring Nginx..."
        configure_nginx
    else
        ((current_step++))
        echo -e "${YELLOW}[${current_step}/${total_steps}] Skipping Nginx configuration${NC}"
    fi
    
    # Step 11: Setup SSL
    if [[ "$INSTALL_SSL" == "Y" ]] || [[ "$INSTALL_SSL" == "y" ]]; then
        ((current_step++))
        show_progress $current_step $total_steps "Setting up SSL certificate..."
        setup_ssl
    else
        ((current_step++))
        echo -e "${YELLOW}[${current_step}/${total_steps}] Skipping SSL setup${NC}"
    fi
    
    # Step 12: Setup Services
    ((current_step++))
    show_progress $current_step $total_steps "Setting up system services..."
    setup_services
    
    # Finish installation
    finish_installation
}

# Error handling
trap 'echo -e "${RED}Installation failed. Check log for details.${NC}"; exit 1' ERR

# Run the installation
main_install