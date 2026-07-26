#!/bin/bash
# Codex Panel - OS Detection Module
# This file handles operating system detection and verification

# Function to detect the operating system
detect_os() {
    print_status "step" "Detecting operating system..."
    
    # Check if /etc/os-release exists
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        export OS_NAME="$NAME"
        export OS_VERSION="$VERSION_ID"
        export OS_ID="$ID"
    else
        print_status "error" "Cannot detect operating system (no /etc/os-release file)"
        rollback "OS Detection"
    fi
    
    # Check for supported operating systems
    case "$OS_ID" in
        ubuntu)
            case "$OS_VERSION" in
                22.04|24.04)
                    print_status "success" "Detected $OS_NAME $OS_VERSION - Supported"
                    ;;
                *)
                    print_status "error" "Ubuntu $OS_VERSION is not supported. Only Ubuntu 22.04 and 24.04 are supported."
                    rollback "OS Detection"
                    ;;
            esac
            ;;
        debian)
            case "$OS_VERSION" in
                11|12)
                    print_status "warning" "Debian $OS_VERSION is not officially supported but may work"
                    print_status "warning" "Proceeding with caution..."
                    ;;
                *)
                    print_status "error" "Debian $OS_VERSION is not supported"
                    rollback "OS Detection"
                    ;;
            esac
            ;;
        *)
            print_status "error" "$OS_NAME is not supported. Only Ubuntu 22.04/24.04 are supported."
            rollback "OS Detection"
            ;;
    esac
    
    # Store OS information for later use
    export OS_BITS=$(getconf LONG_BIT)
    export OS_ARCH=$(uname -m)
    
    print_status "info" "OS: $OS_NAME $OS_VERSION ($OS_BITS-bit, $OS_ARCH)"
}

# Function to check system requirements
check_system_requirements() {
    print_status "step" "Checking system requirements..."
    
    local required_ram=1024  # 1GB in MB
    local required_disk=5120  # 5GB in MB
    local required_cores=1
    
    # Check RAM
    check_memory $required_ram || print_status "warning" "Minimum RAM requirement is ${required_ram}MB"
    
    # Check Disk
    check_disk_space $required_disk || print_status "warning" "Minimum disk space requirement is ${required_disk}MB"
    
    # Check CPU
    check_cpu $required_cores || print_status "warning" "Minimum CPU cores requirement is ${required_cores}"
    
    # Check internet
    if ! check_internet; then
        print_status "error" "Internet connectivity is required for installation"
        rollback "System Check"
    fi
    
    # Check domain resolution if domain is set
    if [[ -n "$PANEL_DOMAIN" ]]; then
        if ! domain_resolves "$PANEL_DOMAIN"; then
            print_status "warning" "Domain $PANEL_DOMAIN does not resolve to this server"
            print_status "warning" "SSL certificate installation may fail if the domain doesn't resolve"
        else
            print_status "success" "Domain $PANEL_DOMAIN resolves correctly"
        fi
    fi
    
    print_status "success" "System requirements check completed"
}

# Function to check internet connectivity
check_internet() {
    local test_hosts=("8.8.8.8" "1.1.1.1" "google.com" "github.com")
    
    for host in "${test_hosts[@]}"; do
        if ping -c 1 -W 2 "$host" &>/dev/null; then
            return 0
        fi
    done
    
    # Try HTTPS as fallback
    if curl -s --connect-timeout 5 https://google.com >/dev/null 2>&1; then
        return 0
    fi
    
    return 1
}

# Function to check if running in a container
is_container() {
    if [[ -f /.dockerenv ]] || [[ -f /run/.containerenv ]]; then
        return 0
    fi
    
    if grep -q "container" /proc/1/environ 2>/dev/null; then
        return 0
    fi
    
    return 1
}

# Function to check if running on a VM
is_vm() {
    if systemd-detect-virt -q; then
        return 0
    fi
    
    return 1
}

# Function to get system information
get_system_info() {
    local info=()
    
    info+=("OS: $OS_NAME $OS_VERSION")
    info+=("Kernel: $(uname -r)")
    info+=("Architecture: $(uname -m)")
    info+=("CPU: $(nproc) cores")
    info+=("RAM: $(free -h | awk '/^Mem:/{print $2}')")
    info+=("Disk: $(df -h / | awk 'NR==2 {print $2}')")
    
    if is_container; then
        info+=("Environment: Container")
    elif is_vm; then
        info+=("Environment: Virtual Machine ($(systemd-detect-virt))")
    else
        info+=("Environment: Physical")
    fi
    
    # Print system information
    print_status "info" "System Information:"
    for line in "${info[@]}"; do
        echo -e "  ${WHITE}$line${NC}"
    done
}

# Function to update system packages
update_system() {
    print_status "step" "Updating system packages..."
    
    # Update package lists
    apt-get update -qq 2>&1 | while read -r line; do
        log_message "INFO" "APT UPDATE: $line"
    done
    
    if [[ $? -ne 0 ]]; then
        print_status "error" "Failed to update package lists"
        rollback "System Update"
    fi
    
    # Upgrade packages (non-interactive)
    DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -qq 2>&1 | while read -r line; do
        log_message "INFO" "APT UPGRADE: $line"
    done
    
    if [[ $? -ne 0 ]]; then
        print_status "warning" "Failed to upgrade packages, continuing with installation"
    else
        print_status "success" "System packages updated successfully"
    fi
}