#!/bin/bash
# Codex Panel - Main Installation Bootstrap
# This script is the entry point for the installation process

set -e

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Global variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/var/log/codexpanel-install.log"
REPO_URL="https://github.com/josevijuzen-source/codex-panel.git"
INSTALL_DIR="/opt/codex-panel"

# Function to log messages
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

# Function to print colored output
print_status() {
    local status="$1"
    local message="$2"
    case "$status" in
        "info")
            echo -e "${BLUE}[INFO]${NC} $message"
            log_message "INFO" "$message"
            ;;
        "success")
            echo -e "${GREEN}[✓]${NC} $message"
            log_message "SUCCESS" "$message"
            ;;
        "error")
            echo -e "${RED}[✗]${NC} $message"
            log_message "ERROR" "$message"
            ;;
        "warning")
            echo -e "${YELLOW}[!]${NC} $message"
            log_message "WARNING" "$message"
            ;;
        "step")
            echo -e "${CYAN}[→]${NC} $message"
            log_message "STEP" "$message"
            ;;
        *)
            echo "$message"
            log_message "INFO" "$message"
            ;;
    esac
}

# Function to print header
print_header() {
    clear
    echo -e "${CYAN}======================================${NC}"
    echo -e "${WHITE}      CODEX PANEL INSTALLER${NC}"
    echo -e "${CYAN}======================================${NC}"
    echo ""
}

# Function to check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_status "error" "This script must be run as root. Use: sudo bash $0"
        exit 1
    fi
    print_status "success" "Root privileges confirmed"
}

# Function to detect OS
detect_os() {
    print_status "step" "Detecting operating system..."
    
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
    else
        print_status "error" "Cannot detect operating system"
        exit 1
    fi
    
    case "$OS" in
        "Ubuntu"*)
            if [[ "$VER" == "22.04" ]] || [[ "$VER" == "24.04" ]]; then
                print_status "success" "Detected $OS $VER - Supported"
            else
                print_status "error" "Ubuntu $VER is not supported. Only 22.04 and 24.04 are supported."
                exit 1
            fi
            ;;
        *)
            print_status "error" "$OS is not supported. Only Ubuntu 22.04 and 24.04 are supported."
            exit 1
            ;;
    esac
}

# Function to check system requirements
check_system_requirements() {
    print_status "step" "Checking system requirements..."
    
    # Check RAM
    local total_ram=$(free -m | awk '/^Mem:/{print $2}')
    if [[ $total_ram -lt 1024 ]]; then
        print_status "warning" "Low RAM detected: ${total_ram}MB (Recommended: 1024MB+)"
    else
        print_status "success" "RAM: ${total_ram}MB"
    fi
    
    # Check CPU cores
    local cpu_cores=$(nproc)
    if [[ $cpu_cores -lt 1 ]]; then
        print_status "warning" "Low CPU cores: $cpu_cores (Recommended: 1+)"
    else
        print_status "success" "CPU Cores: $cpu_cores"
    fi
    
    # Check disk space
    local disk_space=$(df -h / | awk 'NR==2 {print $4}')
    print_status "success" "Available disk space: $disk_space"
}

# Function to check internet connectivity
check_internet() {
    print_status "step" "Checking internet connectivity..."
    
    local test_hosts=("8.8.8.8" "1.1.1.1" "github.com")
    local connected=false
    
    for host in "${test_hosts[@]}"; do
        if ping -c 1 -W 2 "$host" &>/dev/null; then
            connected=true
            break
        fi
    done
    
    if [[ "$connected" == true ]]; then
        print_status "success" "Internet connectivity confirmed"
    else
        print_status "error" "No internet connectivity detected"
        exit 1
    fi
}

# Function to install prerequisite packages
install_prerequisites() {
    print_status "step" "Installing prerequisite packages..."
    
    apt-get update -qq
    
    local packages=(
        git
        curl
        wget
        unzip
        software-properties-common
        apt-transport-https
        ca-certificates
        gnupg
        lsb-release
    )
    
    for package in "${packages[@]}"; do
        if dpkg -l | grep -q "^ii  $package "; then
            print_status "info" "Package $package already installed"
        else
            print_status "info" "Installing $package..."
            apt-get install -y "$package" >> "$LOG_FILE" 2>&1
            if [[ $? -eq 0 ]]; then
                print_status "success" "Package $package installed successfully"
            else
                print_status "error" "Failed to install package $package"
                exit 1
            fi
        fi
    done
}

# Function to clone repository
clone_repository() {
    print_status "step" "Cloning Codex Panel repository..."
    
    # Remove existing directory if present
    if [[ -d "$INSTALL_DIR" ]]; then
        print_status "warning" "Existing installation found. Removing..."
        rm -rf "$INSTALL_DIR"
    fi
    
    # Clone the repository
    git clone "$REPO_URL" "$INSTALL_DIR" >> "$LOG_FILE" 2>&1
    
    if [[ $? -eq 0 ]]; then
        print_status "success" "Repository cloned successfully"
    else
        print_status "error" "Failed to clone repository"
        exit 1
    fi
}

# Function to execute the modular installer
execute_installer() {
    print_status "step" "Starting modular installer..."
    
    if [[ ! -d "$INSTALL_DIR/installer" ]]; then
        print_status "error" "Installer directory not found in the repository"
        exit 1
    fi
    
    # Make all scripts executable
    find "$INSTALL_DIR/installer" -name "*.sh" -exec chmod +x {} \;
    
    # Execute the main installer
    cd "$INSTALL_DIR/installer"
    ./install.sh
    
    if [[ $? -eq 0 ]]; then
        print_status "success" "Codex Panel installation completed successfully"
    else
        print_status "error" "Codex Panel installation failed"
        exit 1
    fi
}

# Function to handle errors
error_handler() {
    local line="$1"
    local command="$2"
    print_status "error" "Installation failed at line $line: $command"
    print_status "info" "Check the log file for details: $LOG_FILE"
    exit 1
}

# Set error handler
trap 'error_handler ${LINENO} "$BASH_COMMAND"' ERR

# Main execution
main() {
    # Initialize log file
    if [[ -f "$LOG_FILE" ]]; then
        mv "$LOG_FILE" "$LOG_FILE.old"
    fi
    touch "$LOG_FILE"
    chmod 644 "$LOG_FILE"
    
    print_header
    check_root
    detect_os
    check_system_requirements
    check_internet
    install_prerequisites
    clone_repository
    execute_installer
    
    print_header
    echo -e "${GREEN}======================================${NC}"
    echo -e "${WHITE}      Installation Complete!${NC}"
    echo -e "${GREEN}======================================${NC}"
    echo ""
    echo -e "Panel URL: ${CYAN}https://${PANEL_DOMAIN}${NC}"
    echo -e "Username: ${CYAN}${ADMIN_USERNAME}${NC}"
    echo -e "Password: ${CYAN}${ADMIN_PASSWORD}${NC}"
    echo ""
    echo -e "${YELLOW}Log file: ${LOG_FILE}${NC}"
    echo -e "${GREEN}======================================${NC}"
}

# Run main function
main