#!/bin/bash
# Codex Panel - Common Functions Module
# This file contains utility functions used throughout the installer

# Function to log messages
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Ensure log directory exists
    mkdir -p "$(dirname "$LOG_FILE")"
    
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

# Function to print colored status messages
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

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if a package is installed
package_installed() {
    dpkg -l | grep -q "^ii  $1 "
}

# Function to check if a service is running
service_running() {
    systemctl is-active --quiet "$1"
}

# Function to check if a port is in use
port_in_use() {
    netstat -tuln | grep -q ":$1 "
}

# Function to wait for a service to be ready
wait_for_service() {
    local service="$1"
    local timeout="${2:-60}"
    local interval="${3:-5}"
    local elapsed=0
    
    while [[ $elapsed -lt $timeout ]]; do
        if systemctl is-active --quiet "$service"; then
            return 0
        fi
        sleep "$interval"
        elapsed=$((elapsed + interval))
        print_status "info" "Waiting for $service to start... ($elapsed/$timeout seconds)"
    done
    
    return 1
}

# Function to generate a random password
generate_password() {
    local length="${1:-32}"
    openssl rand -base64 "$length" | tr -d "=+/" | cut -c1-"$length"
}

# Function to create a directory with proper permissions
create_directory() {
    local dir="$1"
    local owner="${2:-root:root}"
    local permissions="${3:-755}"
    
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir"
        chown "$owner" "$dir"
        chmod "$permissions" "$dir"
        print_status "success" "Created directory: $dir"
    else
        print_status "info" "Directory already exists: $dir"
    fi
}

# Function to backup a file
backup_file() {
    local file="$1"
    if [[ -f "$file" ]]; then
        local backup="${file}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$file" "$backup"
        print_status "info" "Backed up: $file -> $backup"
        return 0
    else
        print_status "warning" "File does not exist: $file"
        return 1
    fi
}

# Function to check if a domain resolves
domain_resolves() {
    local domain="$1"
    nslookup "$domain" >/dev/null 2>&1
}

# Function to get server IP
get_server_ip() {
    curl -s -4 ifconfig.me 2>/dev/null || curl -s -4 icanhazip.com 2>/dev/null || echo "127.0.0.1"
}

# Function to check disk space
check_disk_space() {
    local required_mb="$1"
    local available_mb=$(df -m / | awk 'NR==2 {print $4}')
    
    if [[ $available_mb -lt $required_mb ]]; then
        print_status "error" "Insufficient disk space. Required: ${required_mb}MB, Available: ${available_mb}MB"
        return 1
    fi
    
    print_status "success" "Sufficient disk space: ${available_mb}MB available"
    return 0
}

# Function to check memory
check_memory() {
    local required_mb="$1"
    local total_mb=$(free -m | awk '/^Mem:/{print $2}')
    
    if [[ $total_mb -lt $required_mb ]]; then
        print_status "warning" "Low memory. Required: ${required_mb}MB, Available: ${total_mb}MB"
        return 1
    fi
    
    print_status "success" "Sufficient memory: ${total_mb}MB available"
    return 0
}

# Function to check CPU
check_cpu() {
    local required_cores="$1"
    local total_cores=$(nproc)
    
    if [[ $total_cores -lt $required_cores ]]; then
        print_status "warning" "Low CPU cores. Required: ${required_cores}, Available: ${total_cores}"
        return 1
    fi
    
    print_status "success" "Sufficient CPU: ${total_cores} cores available"
    return 0
}

# Function to rollback on error
rollback() {
    local step="$1"
    print_status "error" "Installation failed at step: $step"
    print_status "info" "Starting rollback..."
    
    # Stop services
    if systemctl is-active --quiet "$SERVICE_NAME" 2>/dev/null; then
        systemctl stop "$SERVICE_NAME"
        print_status "info" "Stopped $SERVICE_NAME service"
    fi
    
    # Remove Nginx configuration
    if [[ -f "$NGINX_SITES_AVAILABLE/$PANEL_DOMAIN" ]]; then
        rm -f "$NGINX_SITES_AVAILABLE/$PANEL_DOMAIN"
        rm -f "$NGINX_SITES_ENABLED/$PANEL_DOMAIN"
        systemctl reload nginx
        print_status "info" "Removed Nginx configuration"
    fi
    
    # Remove SSL certificates
    if [[ -d "$SSL_DIR/$PANEL_DOMAIN" ]]; then
        rm -rf "$SSL_DIR/$PANEL_DOMAIN"
        print_status "info" "Removed SSL certificates"
    fi
    
    # Remove installation directory
    if [[ -d "$INSTALL_DIR" ]]; then
        rm -rf "$INSTALL_DIR"
        print_status "info" "Removed installation directory"
    fi
    
    print_status "warning" "Rollback completed. Please check the log file for details."
    exit 1
}