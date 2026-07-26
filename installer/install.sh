#!/bin/bash
# Codex Panel - Main Installer Orchestration Script
# This script orchestrates the complete installation process

set -Eeuo pipefail

# ============================================================================
# GLOBAL VARIABLES
# ============================================================================

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly INSTALLER_VERSION="1.0.0"
readonly LOG_DIR="/var/log/codexpanel"
readonly LOG_FILE="${LOG_DIR}/codexpanel-install-$(date +%Y%m%d-%H%M%S).log"
readonly CONFIG_FILE="${SCRIPT_DIR}/.install.config"
readonly STATE_FILE="${SCRIPT_DIR}/.install.state"
readonly MIN_RAM_MB=1024
readonly MIN_DISK_MB=5120
readonly MIN_CPU_CORES=1

# Ensure INSTALL_DIR is defined
INSTALL_DIR="${INSTALL_DIR:-/opt/codex-panel}"
export INSTALL_DIR

# Configuration variables with defaults
SYSTEMD_SERVICE_NAME="${SYSTEMD_SERVICE_NAME:-codex-panel}"
BACKEND_PORT="${BACKEND_PORT:-3000}"
BACKEND_HEALTH_ENDPOINT="${BACKEND_HEALTH_ENDPOINT:-/health}"
FRONTEND_DEPLOY_DIR="${FRONTEND_DEPLOY_DIR:-/var/www/codexpanel/frontend}"
SSL_LIVE_DIR="${SSL_LIVE_DIR:-/etc/letsencrypt/live}"
SSL_SELF_SIGNED_DIR="${SSL_SELF_SIGNED_DIR:-/etc/ssl/codexpanel}"

export SYSTEMD_SERVICE_NAME BACKEND_PORT BACKEND_HEALTH_ENDPOINT
export FRONTEND_DEPLOY_DIR SSL_LIVE_DIR SSL_SELF_SIGNED_DIR

# Color definitions
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly NC='\033[0m'

# Installation tracking
INSTALLATION_STEP=""
INSTALLATION_MODULE=""
INSTALLATION_START_TIME=""
INSTALLATION_END_TIME=""
INSTALLATION_PARTIAL=false
DRY_RUN="${DRY_RUN:-false}"
RESUME="${RESUME:-false}"
NON_INTERACTIVE="${NON_INTERACTIVE:-false}"
declare -a COMPLETED_STEPS=()

# Sensitive data - kept only in memory
ADMIN_PASSWORD=""
ADMIN_PASSWORD_CONFIRM=""

# ============================================================================
# LOGGING FUNCTIONS
# ============================================================================

log_info() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] [INFO] ${message}" >> "${LOG_FILE}"
}

log_warn() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] [WARN] ${message}" >> "${LOG_FILE}"
}

log_error() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] [ERROR] ${message}" >> "${LOG_FILE}"
}

log_success() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] [SUCCESS] ${message}" >> "${LOG_FILE}"
}

log_module_start() {
    local module="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] [MODULE] START: ${module}" >> "${LOG_FILE}"
}

log_module_end() {
    local module="$1"
    local status="$2"
    local duration="$3"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] [MODULE] ${status}: ${module} (${duration}s)" >> "${LOG_FILE}"
}

print_status() {
    local status="$1"
    local message="$2"
    
    if [[ "${DRY_RUN}" == "true" ]] && [[ "${status}" != "error" ]]; then
        echo -e "${YELLOW}[DRY-RUN]${NC} ${message}"
        return
    fi
    
    case "${status}" in
        "info")
            echo -e "${BLUE}[INFO]${NC} ${message}"
            log_info "${message}"
            ;;
        "success")
            echo -e "${GREEN}[✓]${NC} ${message}"
            log_success "${message}"
            ;;
        "error")
            echo -e "${RED}[✗]${NC} ${message}"
            log_error "${message}"
            ;;
        "warning")
            echo -e "${YELLOW}[!]${NC} ${message}"
            log_warn "${message}"
            ;;
        "step")
            echo -e "${CYAN}[→]${NC} ${message}"
            log_info "STEP: ${message}"
            ;;
        *)
            echo "${message}"
            log_info "${message}"
            ;;
    esac
}

# ============================================================================
# ERROR HANDLER
# ============================================================================

error_handler() {
    local line="$1"
    local command="$2"
    local code="${3:-1}"
    
    echo -e "\n${RED}========================================${NC}"
    echo -e "${RED}  INSTALLATION FAILED${NC}"
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}Error:${NC} Command failed with exit code ${code}"
    echo -e "${RED}Line:${NC} ${line}"
    echo -e "${RED}Command:${NC} ${command}"
    echo -e "${RED}Module:${NC} ${INSTALLATION_MODULE:-install.sh}"
    echo -e "${RED}Step:${NC} ${INSTALLATION_STEP:-Unknown}"
    echo -e "${RED}Time:${NC} $(date)"
    echo -e "${RED}Log File:${NC} ${LOG_FILE}"
    echo -e "${RED}========================================${NC}"
    
    if [[ "${INSTALLATION_PARTIAL}" == true ]]; then
        echo -e "${YELLOW}Partial installation detected.${NC}"
        echo -e "${YELLOW}Some components may have been installed.${NC}"
        echo -e "${YELLOW}Review the log file before retrying.${NC}"
        echo -e "${YELLOW}To resume from the last successful step, use:${NC}"
        echo -e "${WHITE}  bash install.sh --resume${NC}"
    fi
    
    echo -e "${YELLOW}Troubleshooting:${NC}"
    echo -e "  1. Check the log file for detailed errors: ${WHITE}tail -f ${LOG_FILE}${NC}"
    echo -e "  2. Ensure all system requirements are met"
    echo -e "  3. Try running the installer again"
    echo -e "  4. If the issue persists, check the documentation"
    echo -e "${RED}========================================${NC}"
    
    # Save state for resume
    save_state
    
    exit 1
}

cleanup_handler() {
    local signal="$1"
    echo -e "\n${YELLOW}Installation interrupted by signal ${signal}.${NC}"
    echo -e "${YELLOW}Partial installation may exist.${NC}"
    echo -e "${YELLOW}Log file: ${LOG_FILE}${NC}"
    echo -e "${YELLOW}To resume from the last successful step, use:${NC}"
    echo -e "${WHITE}  bash install.sh --resume${NC}"
    save_state
    exit 1
}

trap 'error_handler ${LINENO} "$BASH_COMMAND" $?' ERR
trap 'cleanup_handler INT' INT
trap 'cleanup_handler TERM' TERM
trap 'cleanup_handler HUP' HUP
trap 'cleanup_handler QUIT' QUIT

# ============================================================================
# HEADER DISPLAY
# ============================================================================

display_header() {
    clear
    echo -e "${CYAN}========================================${NC}"
    echo -e "${WHITE}        CODEX PANEL INSTALLER${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}Version:${NC} ${WHITE}${INSTALLER_VERSION}${NC}"
    echo -e "${CYAN}System:${NC} ${WHITE}$(uname -s) $(uname -r)${NC}"
    echo -e "${CYAN}Architecture:${NC} ${WHITE}$(uname -m)${NC}"
    echo -e "${CYAN}Install Dir:${NC} ${WHITE}${INSTALL_DIR}${NC}"
    echo -e "${CYAN}Log File:${NC} ${WHITE}${LOG_FILE}${NC}"
    
    if [[ "${DRY_RUN}" == "true" ]]; then
        echo -e "${YELLOW}Mode:${NC} ${WHITE}DRY-RUN (No changes will be made)${NC}"
    fi
    
    if [[ "${RESUME}" == "true" ]]; then
        echo -e "${YELLOW}Mode:${NC} ${WHITE}RESUME (Continuing from last successful step)${NC}"
    fi
    
    echo -e "${CYAN}========================================${NC}"
    echo ""
}

# ============================================================================
# MODULE LOADING
# ============================================================================

declare -A REQUIRED_FUNCTIONS=(
    ["config.sh"]=""
    ["functions.sh"]=""
    ["os.sh"]="detect_os check_system_requirements"
    ["packages.sh"]="update_system install_required_packages"
    ["database.sh"]="install_mariadb install_redis"
    ["node.sh"]="install_node"
    ["backend.sh"]="install_backend"
    ["frontend.sh"]="install_frontend"
    ["nginx.sh"]="setup_nginx"
    ["ssl.sh"]="setup_ssl"
    ["service.sh"]="setup_service"
    ["finish.sh"]="finish_installation"
)

validate_module_file() {
    local module_path="$1"
    local module_name="$2"
    
    if [[ ! -f "${module_path}" ]]; then
        print_status "error" "Module not found: ${module_name}"
        return 1
    fi
    
    if [[ ! -r "${module_path}" ]]; then
        print_status "error" "Module not readable: ${module_name}"
        return 1
    fi
    
    return 0
}

load_modules() {
    print_status "step" "Loading installation modules..."
    
    local modules=(
        "config.sh"
        "functions.sh"
        "os.sh"
        "packages.sh"
        "database.sh"
        "node.sh"
        "backend.sh"
        "frontend.sh"
        "nginx.sh"
        "ssl.sh"
        "service.sh"
        "finish.sh"
    )
    
    # Temporarily disable unset variable checking during module loading
    set +u
    
    for module in "${modules[@]}"; do
        local module_path="${SCRIPT_DIR}/${module}"
        local module_start_time=$(date +%s)
        
        log_module_start "${module}"
        
        if ! validate_module_file "${module_path}" "${module}"; then
            exit 1
        fi
        
        # shellcheck source=/dev/null
        source "${module_path}"
        
        # Verify required functions exist
        local required_funcs="${REQUIRED_FUNCTIONS[${module}]:-}"
        if [[ -n "${required_funcs}" ]]; then
            for func in ${required_funcs}; do
                if ! declare -F "${func}" > /dev/null 2>&1; then
                    print_status "error" "Module ${module} loaded but function ${func} not found"
                    exit 1
                fi
            done
        fi
        
        local module_end_time=$(date +%s)
        local module_duration=$((module_end_time - module_start_time))
        
        log_module_end "${module}" "LOADED" "${module_duration}"
        print_status "info" "Loaded module: ${module}"
    done
    
    # Re-enable unset variable checking
    set -u
    
    # Verify all core functions are available
    local core_functions=(
        "detect_os"
        "check_system_requirements"
        "update_system"
        "install_required_packages"
        "install_node"
        "install_mariadb"
        "install_redis"
        "install_backend"
        "install_frontend"
        "setup_nginx"
        "setup_ssl"
        "setup_service"
        "finish_installation"
    )
    
    for func in "${core_functions[@]}"; do
        if ! declare -F "${func}" > /dev/null 2>&1; then
            print_status "error" "Required function ${func} not available"
            exit 1
        fi
    done
    
    print_status "success" "All modules loaded successfully"
}

# ============================================================================
# STATE MANAGEMENT
# ============================================================================

save_state() {
    if [[ "${DRY_RUN}" == "true" ]]; then
        return
    fi
    
    # Generate unique installation ID
    local install_id
    if command -v uuidgen > /dev/null 2>&1; then
        install_id=$(uuidgen)
    else
        install_id="codex-$(date +%Y%m%d-%H%M%S)-$(openssl rand -hex 8 2>/dev/null || echo "${RANDOM}${RANDOM}")"
    fi
    
    # Create state file in key=value format (safe, no sourcing)
    {
        echo "# Codex Panel Installation State"
        echo "# Generated: $(date)"
        echo "INSTALLER_VERSION=${INSTALLER_VERSION}"
        echo "INSTALLATION_ID=${install_id}"
        echo "INSTALLATION_DATE=$(date +%Y%m%d-%H%M%S)"
        echo "OS=$(uname -s)"
        echo "KERNEL=$(uname -r)"
        echo "INSTALL_DIR=${INSTALL_DIR}"
        echo "PANEL_DOMAIN=${PANEL_DOMAIN:-}"
        echo "ADMIN_USERNAME=${ADMIN_USERNAME:-}"
        echo "INSTALL_MARIADB=${INSTALL_MARIADB:-}"
        echo "INSTALL_REDIS=${INSTALL_REDIS:-}"
        echo "INSTALL_NGINX=${INSTALL_NGINX:-}"
        echo "INSTALL_SSL=${INSTALL_SSL:-}"
        echo "SYSTEMD_SERVICE_NAME=${SYSTEMD_SERVICE_NAME}"
        echo "BACKEND_PORT=${BACKEND_PORT}"
        echo "LAST_STEP=${INSTALLATION_STEP:-}"
        echo "LAST_MODULE=${INSTALLATION_MODULE:-}"
        echo "INSTALLATION_PARTIAL=${INSTALLATION_PARTIAL}"
        echo "COMPLETED_STEPS_COUNT=${#COMPLETED_STEPS[@]}"
        
        # Write completed steps as comma-separated list
        local steps_list
        steps_list=$(IFS=,; echo "${COMPLETED_STEPS[*]}")
        echo "COMPLETED_STEPS_LIST=${steps_list}"
    } > "${STATE_FILE}"
    
    chmod 600 "${STATE_FILE}"
}

load_state() {
    if [[ ! -f "${STATE_FILE}" ]]; then
        return 1
    fi
    
    # Parse state file safely (no sourcing)
    local state_installer_version=""
    local state_install_dir=""
    local state_panel_domain=""
    local state_os=""
    local state_kernel=""
    local state_steps_list=""
    local state_last_step=""
    local state_install_id=""
    
    while IFS= read -r line; do
        # Skip comments and empty lines
        [[ "${line}" =~ ^#.*$ ]] && continue
        [[ -z "${line}" ]] && continue
        
        # Split on first '=' only
        local key="${line%%=*}"
        local value="${line#*=}"
        
        # Trim whitespace
        key="${key%% }"
        key="${key## }"
        value="${value%% }"
        value="${value## }"
        
        case "${key}" in
            "INSTALLER_VERSION") state_installer_version="${value}" ;;
            "INSTALL_ID"|"INSTALLATION_ID") state_install_id="${value}" ;;
            "INSTALL_DIR") state_install_dir="${value}" ;;
            "PANEL_DOMAIN") state_panel_domain="${value}" ;;
            "OS") state_os="${value}" ;;
            "KERNEL") state_kernel="${value}" ;;
            "LAST_STEP") state_last_step="${value}" ;;
            "COMPLETED_STEPS_LIST") state_steps_list="${value}" ;;
        esac
    done < "${STATE_FILE}"
    
    # Validate installer version matches
    if [[ -n "${state_installer_version}" ]] && [[ "${state_installer_version}" != "${INSTALLER_VERSION}" ]]; then
        print_status "error" "Saved installer version (${state_installer_version}) does not match current (${INSTALLER_VERSION})"
        print_status "error" "Cannot resume installation from a different installer version"
        return 1
    fi
    
    # Validate state matches current environment
    if [[ -n "${state_install_dir}" ]] && [[ "${state_install_dir}" != "${INSTALL_DIR}" ]]; then
        print_status "error" "Saved installation directory (${state_install_dir}) does not match current (${INSTALL_DIR})"
        return 1
    fi
    
    if [[ -n "${state_os}" ]] && [[ "${state_os}" != "$(uname -s)" ]]; then
        print_status "error" "Saved OS (${state_os}) does not match current ($(uname -s))"
        return 1
    fi
    
    if [[ -n "${state_panel_domain}" ]] && [[ -n "${PANEL_DOMAIN:-}" ]] && [[ "${state_panel_domain}" != "${PANEL_DOMAIN}" ]]; then
        print_status "error" "Saved panel domain (${state_panel_domain}) does not match current (${PANEL_DOMAIN})"
        return 1
    fi
    
    # Restore completed steps from comma-separated list
    if [[ -n "${state_steps_list}" ]]; then
        IFS=',' read -ra COMPLETED_STEPS <<< "${state_steps_list}"
    fi
    
    print_status "info" "Loaded installation state (ID: ${state_install_id:-unknown})"
    print_status "info" "Installer version: ${state_installer_version:-${INSTALLER_VERSION}}"
    print_status "info" "Last completed step: ${state_last_step:-None}"
    print_status "info" "Completed steps: ${state_steps_list:-None}"
    
    return 0
}

cleanup_state() {
    if [[ -f "${STATE_FILE}" ]]; then
        rm -f "${STATE_FILE}" 2>/dev/null || true
        print_status "info" "Cleaned up installation state"
    fi
}

# ============================================================================
# STEP EXECUTION HELPER
# ============================================================================

is_step_completed() {
    local step_name="$1"
    
    if [[ "${RESUME}" == "true" ]]; then
        for step in "${COMPLETED_STEPS[@]}"; do
            if [[ "${step}" == "${step_name}" ]]; then
                return 0
            fi
        done
    fi
    
    return 1
}

mark_step_completed() {
    local step_name="$1"
    
    if [[ "${DRY_RUN}" == "true" ]]; then
        return
    fi
    
    COMPLETED_STEPS+=("${step_name}")
    save_state
}

execute_step() {
    local step_name="$1"
    local step_function="$2"
    local step_module="${3:-${step_function}}"
    local step_optional="${4:-false}"
    local current_step="$5"
    local total_steps="$6"
    
    # Check if step is already completed in resume mode
    if is_step_completed "${step_name}"; then
        print_status "info" "Skipping already completed step: ${step_name}"
        return 0
    fi
    
    INSTALLATION_STEP="${step_name}"
    INSTALLATION_MODULE="${step_module}"
    
    # Show progress
    local percent=$((current_step * 100 / total_steps))
    echo -e "${CYAN}[${current_step}/${total_steps}]${NC} ${step_name} ${WHITE}(${percent}%)${NC}"
    
    local step_start_time=$(date +%s)
    log_module_start "${step_name}"
    
    # Check if step function exists
    if ! declare -F "${step_function}" > /dev/null 2>&1; then
        print_status "error" "Function ${step_function} not found for step ${step_name}"
        return 1
    fi
    
    # DRY-RUN: Skip actual execution
    if [[ "${DRY_RUN}" == "true" ]]; then
        print_status "info" "DRY-RUN: Would execute ${step_name}"
        mark_step_completed "${step_name}"
        return 0
    fi
    
    # Execute the step
    if "${step_function}"; then
        local step_end_time=$(date +%s)
        local step_duration=$((step_end_time - step_start_time))
        
        log_module_end "${step_name}" "SUCCESS" "${step_duration}"
        print_status "success" "Completed: ${step_name} (${step_duration}s)"
        
        mark_step_completed "${step_name}"
        return 0
    else
        local step_end_time=$(date +%s)
        local step_duration=$((step_end_time - step_start_time))
        
        log_module_end "${step_name}" "FAILED" "${step_duration}"
        
        if [[ "${step_optional}" == "true" ]]; then
            print_status "warning" "Optional step failed: ${step_name}"
            mark_step_completed "${step_name}"
            return 0
        else
            print_status "error" "Failed: ${step_name}"
            INSTALLATION_PARTIAL=true
            return 1
        fi
    fi
}

# ============================================================================
# VALIDATION FUNCTIONS
# ============================================================================

validate_domain() {
    local domain="$1"
    
    if [[ -z "${domain}" ]]; then
        return 1
    fi
    
    if [[ ! "${domain}" =~ ^([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$ ]]; then
        return 1
    fi
    
    if [[ "${domain}" == "localhost" ]] || [[ "${domain}" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        return 1
    fi
    
    return 0
}

validate_email() {
    local email="$1"
    
    if [[ -z "${email}" ]]; then
        return 1
    fi
    
    if [[ ! "${email}" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
        return 1
    fi
    
    return 0
}

validate_username() {
    local username="$1"
    
    if [[ -z "${username}" ]]; then
        return 1
    fi
    
    if [[ ${#username} -lt 3 ]]; then
        return 1
    fi
    
    if [[ "${username}" =~ [[:space:]] ]]; then
        return 1
    fi
    
    if [[ ! "${username}" =~ ^[a-zA-Z0-9_]+$ ]]; then
        return 1
    fi
    
    return 0
}

validate_password() {
    local password="$1"
    
    if [[ -z "${password}" ]]; then
        return 1
    fi
    
    if [[ ${#password} -lt 8 ]]; then
        return 1
    fi
    
    return 0
}

validate_config_variables() {
    local missing=()
    
    [[ -z "${PANEL_DOMAIN:-}" ]] && missing+=("PANEL_DOMAIN")
    [[ -z "${ADMIN_EMAIL:-}" ]] && missing+=("ADMIN_EMAIL")
    [[ -z "${ADMIN_USERNAME:-}" ]] && missing+=("ADMIN_USERNAME")
    [[ -z "${ADMIN_PASSWORD:-}" ]] && missing+=("ADMIN_PASSWORD")
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        print_status "error" "Missing required configuration variables:"
        for var in "${missing[@]}"; do
            echo -e "  ${RED}•${NC} ${var}"
        done
        return 1
    fi
    
    # Validate values
    if ! validate_domain "${PANEL_DOMAIN}"; then
        print_status "error" "Invalid domain: ${PANEL_DOMAIN}"
        return 1
    fi
    
    if ! validate_email "${ADMIN_EMAIL}"; then
        print_status "error" "Invalid email: ${ADMIN_EMAIL}"
        return 1
    fi
    
    if ! validate_username "${ADMIN_USERNAME}"; then
        print_status "error" "Invalid username: ${ADMIN_USERNAME}"
        return 1
    fi
    
    if ! validate_password "${ADMIN_PASSWORD}"; then
        print_status "error" "Invalid password (must be at least 8 characters)"
        return 1
    fi
    
    return 0
}

# ============================================================================
# PRE-FLIGHT CHECKS
# ============================================================================

pre_flight_checks() {
    print_status "step" "Performing pre-flight checks..."
    
    # Check root privileges
    if [[ "${EUID}" -ne 0 ]]; then
        print_status "error" "This script must be run as root"
        if command -v sudo > /dev/null 2>&1; then
            echo -e "Use: ${WHITE}sudo bash ${BASH_SOURCE[0]}${NC}"
        else
            echo -e "Please run as root: ${WHITE}su -${NC}"
        fi
        exit 1
    fi
    print_status "success" "Root privileges confirmed"
    
    # Check required commands
    local required_commands=("curl" "git" "bash" "systemctl" "apt" "wget")
    for cmd in "${required_commands[@]}"; do
        if ! command -v "${cmd}" > /dev/null 2>&1; then
            print_status "error" "Required command not found: ${cmd}"
            exit 1
        fi
    done
    print_status "success" "Required commands available"
    
    # Check network connectivity using HTTPS
    local connected=false
    local test_urls=("https://github.com" "https://google.com" "https://1.1.1.1")
    
    for url in "${test_urls[@]}"; do
        if curl -fsSL --connect-timeout 5 --max-time 10 "${url}" > /dev/null 2>&1; then
            connected=true
            break
        fi
    done
    
    if [[ "${connected}" == false ]]; then
        print_status "error" "No network connectivity detected"
        exit 1
    fi
    print_status "success" "Network connectivity confirmed"
    
    # Check DNS resolution
    local dns_ok=false
    if command -v getent > /dev/null 2>&1; then
        if getent hosts github.com > /dev/null 2>&1; then
            dns_ok=true
        fi
    elif command -v host > /dev/null 2>&1; then
        if host github.com > /dev/null 2>&1; then
            dns_ok=true
        fi
    elif command -v nslookup > /dev/null 2>&1; then
        if nslookup github.com > /dev/null 2>&1; then
            dns_ok=true
        fi
    else
        # Fallback: try to resolve using ping
        if ping -c 1 -W 2 github.com > /dev/null 2>&1; then
            dns_ok=true
        fi
    fi
    
    if [[ "${dns_ok}" == true ]]; then
        print_status "success" "DNS resolution working"
    else
        print_status "warning" "DNS resolution may be slow or failing"
    fi
    
    # Check RAM
    local total_ram
    total_ram=$(free -m | awk '/^Mem:/{print $2}')
    if [[ ${total_ram} -lt ${MIN_RAM_MB} ]]; then
        print_status "error" "Insufficient RAM. Required: ${MIN_RAM_MB}MB, Available: ${total_ram}MB"
        exit 1
    fi
    print_status "success" "RAM: ${total_ram}MB (minimum: ${MIN_RAM_MB}MB)"
    
    # Check disk space
    local available_disk
    available_disk=$(df -m / | awk 'NR==2 {print $4}')
    if [[ ${available_disk} -lt ${MIN_DISK_MB} ]]; then
        print_status "error" "Insufficient disk space. Required: ${MIN_DISK_MB}MB, Available: ${available_disk}MB"
        exit 1
    fi
    print_status "success" "Disk space: ${available_disk}MB (minimum: ${MIN_DISK_MB}MB)"
    
    # Check CPU cores
    local cpu_cores
    cpu_cores=$(nproc)
    if [[ ${cpu_cores} -lt ${MIN_CPU_CORES} ]]; then
        print_status "error" "Insufficient CPU cores. Required: ${MIN_CPU_CORES}, Available: ${cpu_cores}"
        exit 1
    fi
    print_status "success" "CPU cores: ${cpu_cores} (minimum: ${MIN_CPU_CORES})"
    
    print_status "success" "All pre-flight checks passed"
}

# ============================================================================
# USER INPUT COLLECTION
# ============================================================================

collect_user_input() {
    if [[ "${NON_INTERACTIVE}" == "true" ]]; then
        print_status "info" "Non-interactive mode: using environment variables"
        
        if ! validate_config_variables; then
            exit 1
        fi
        
        # Use environment variables
        INSTALL_MARIADB="${INSTALL_MARIADB:-Y}"
        INSTALL_REDIS="${INSTALL_REDIS:-Y}"
        INSTALL_NGINX="${INSTALL_NGINX:-Y}"
        INSTALL_SSL="${INSTALL_SSL:-Y}"
        
        print_status "success" "Configuration loaded from environment variables"
        return
    fi
    
    print_status "step" "Collecting installation parameters..."
    echo ""
    
    # Panel Domain
    while true; do
        read -r -p "Panel Domain (e.g., panel.example.com): " PANEL_DOMAIN
        if validate_domain "${PANEL_DOMAIN}"; then
            break
        else
            echo -e "${RED}Invalid domain format. Please enter a valid FQDN.${NC}"
        fi
    done
    
    # Admin Email
    while true; do
        read -r -p "Admin Email: " ADMIN_EMAIL
        if validate_email "${ADMIN_EMAIL}"; then
            break
        else
            echo -e "${RED}Invalid email format. Please enter a valid email address.${NC}"
        fi
    done
    
    # Admin Username
    while true; do
        read -r -p "Admin Username (min 3 characters): " ADMIN_USERNAME
        if validate_username "${ADMIN_USERNAME}"; then
            break
        else
            echo -e "${RED}Invalid username. Use 3+ alphanumeric characters, no spaces.${NC}"
        fi
    done
    
    # Admin Password
    while true; do
        read -r -s -p "Admin Password (min 8 characters): " ADMIN_PASSWORD
        echo ""
        if validate_password "${ADMIN_PASSWORD}"; then
            break
        else
            echo -e "${RED}Password must be at least 8 characters.${NC}"
        fi
    done
    
    # Confirm Password
    while true; do
        read -r -s -p "Confirm Admin Password: " ADMIN_PASSWORD_CONFIRM
        echo ""
        if [[ "${ADMIN_PASSWORD}" == "${ADMIN_PASSWORD_CONFIRM}" ]]; then
            break
        else
            echo -e "${RED}Passwords do not match. Please try again.${NC}"
        fi
    done
    
    echo ""
    
    # Optional components
    read -r -p "Install MariaDB? [Y/n]: " INSTALL_MARIADB
    INSTALL_MARIADB=${INSTALL_MARIADB:-Y}
    
    read -r -p "Install Redis? [Y/n]: " INSTALL_REDIS
    INSTALL_REDIS=${INSTALL_REDIS:-Y}
    
    read -r -p "Install Nginx? [Y/n]: " INSTALL_NGINX
    INSTALL_NGINX=${INSTALL_NGINX:-Y}
    
    read -r -p "Install SSL (Let's Encrypt)? [Y/n]: " INSTALL_SSL
    INSTALL_SSL=${INSTALL_SSL:-Y}
    
    echo ""
}

# ============================================================================
# CONFIGURATION MANAGEMENT
# ============================================================================

save_config() {
    print_status "step" "Saving installation configuration..."
    
    if [[ "${DRY_RUN}" == "true" ]]; then
        print_status "info" "DRY-RUN: Would save configuration to ${CONFIG_FILE}"
        return
    fi
    
    # DO NOT store ADMIN_PASSWORD in config file
    cat > "${CONFIG_FILE}" <<EOF
# Codex Panel Installation Configuration
# Generated: $(date)

PANEL_DOMAIN="${PANEL_DOMAIN}"
ADMIN_EMAIL="${ADMIN_EMAIL}"
ADMIN_USERNAME="${ADMIN_USERNAME}"
# ADMIN_PASSWORD is not stored in config for security
INSTALL_MARIADB="${INSTALL_MARIADB}"
INSTALL_REDIS="${INSTALL_REDIS}"
INSTALL_NGINX="${INSTALL_NGINX}"
INSTALL_SSL="${INSTALL_SSL}"
INSTALL_DIR="${INSTALL_DIR}"
SYSTEMD_SERVICE_NAME="${SYSTEMD_SERVICE_NAME}"
BACKEND_PORT="${BACKEND_PORT}"
BACKEND_HEALTH_ENDPOINT="${BACKEND_HEALTH_ENDPOINT}"
FRONTEND_DEPLOY_DIR="${FRONTEND_DEPLOY_DIR}"
SSL_LIVE_DIR="${SSL_LIVE_DIR}"
SSL_SELF_SIGNED_DIR="${SSL_SELF_SIGNED_DIR}"
EOF
    
    chmod 600 "${CONFIG_FILE}"
    print_status "success" "Configuration saved to: ${CONFIG_FILE}"
}

load_config() {
    if [[ -f "${CONFIG_FILE}" ]]; then
        # Temporarily disable unset variable checking
        set +u
        # shellcheck source=/dev/null
        source "${CONFIG_FILE}"
        set -u
        
        # ADMIN_PASSWORD is not stored in config, must be set from environment or user input
        if [[ -z "${ADMIN_PASSWORD:-}" ]]; then
            print_status "warning" "ADMIN_PASSWORD not found in config (security). Will need to be provided."
        fi
        
        print_status "success" "Configuration loaded"
        return 0
    else
        print_status "error" "Configuration file not found"
        return 1
    fi
}

# ============================================================================
# PROGRESS DISPLAY
# ============================================================================

calculate_total_steps() {
    local total=9  # Mandatory steps: OS, System Check, Update, Packages, Node, Backend, Frontend, Service, Finish
    
    if [[ "${INSTALL_MARIADB}" =~ ^[Yy]$ ]]; then
        total=$((total + 1))
    fi
    
    if [[ "${INSTALL_REDIS}" =~ ^[Yy]$ ]]; then
        total=$((total + 1))
    fi
    
    if [[ "${INSTALL_NGINX}" =~ ^[Yy]$ ]]; then
        total=$((total + 1))
    fi
    
    if [[ "${INSTALL_SSL}" =~ ^[Yy]$ ]]; then
        total=$((total + 1))
    fi
    
    echo "${total}"
}

# ============================================================================
# FINAL VERIFICATION
# ============================================================================

final_verification() {
    print_status "step" "Performing final verification..."
    
    if [[ "${DRY_RUN}" == "true" ]]; then
        print_status "info" "DRY-RUN: Would verify installation"
        return 0
    fi
    
    local all_ok=true
    local verification_errors=()
    
    # Verify systemd service
    if systemctl is-active --quiet "${SYSTEMD_SERVICE_NAME}" 2>/dev/null; then
        print_status "success" "Codex Panel service: Running"
    else
        print_status "error" "Codex Panel service: Not running"
        verification_errors+=("Codex Panel service not running")
        all_ok=false
    fi
    
    if systemctl is-enabled --quiet "${SYSTEMD_SERVICE_NAME}" 2>/dev/null; then
        print_status "success" "Codex Panel service: Enabled"
    else
        print_status "error" "Codex Panel service: Not enabled"
        verification_errors+=("Codex Panel service not enabled")
        all_ok=false
    fi
    
    # Verify backend health
    if curl -fsSL --connect-timeout 5 --max-time 10 "http://localhost:${BACKEND_PORT}${BACKEND_HEALTH_ENDPOINT}" > /dev/null 2>&1; then
        print_status "success" "Backend API: Healthy (port ${BACKEND_PORT})"
    else
        print_status "warning" "Backend API: Not responding (port ${BACKEND_PORT})"
        verification_errors+=("Backend API not responding")
        all_ok=false
    fi
    
    # Verify frontend deployment
    if [[ -d "${FRONTEND_DEPLOY_DIR}" ]] && [[ -f "${FRONTEND_DEPLOY_DIR}/index.html" ]]; then
        print_status "success" "Frontend: Deployed to ${FRONTEND_DEPLOY_DIR}"
    elif [[ -d "${INSTALL_DIR}/frontend/dist" ]] && [[ -f "${INSTALL_DIR}/frontend/dist/index.html" ]]; then
        print_status "success" "Frontend: Deployed to ${INSTALL_DIR}/frontend/dist"
    else
        print_status "warning" "Frontend: Not found"
        verification_errors+=("Frontend not deployed")
        all_ok=false
    fi
    
    # Verify Nginx
    if command -v nginx > /dev/null 2>&1; then
        if nginx -t > /dev/null 2>&1; then
            print_status "success" "Nginx configuration: Valid"
        else
            print_status "error" "Nginx configuration: Invalid"
            verification_errors+=("Nginx configuration invalid")
            all_ok=false
        fi
        
        if systemctl is-active --quiet nginx 2>/dev/null; then
            print_status "success" "Nginx service: Running"
        else
            print_status "error" "Nginx service: Not running"
            verification_errors+=("Nginx service not running")
            all_ok=false
        fi
    else
        print_status "info" "Nginx: Not installed (skipping verification)"
    fi
    
    # Verify SSL certificate if installed
    if [[ "${INSTALL_SSL}" =~ ^[Yy]$ ]]; then
        if [[ -f "${SSL_LIVE_DIR}/${PANEL_DOMAIN}/fullchain.pem" ]]; then
            print_status "success" "SSL certificate: Installed (Let's Encrypt)"
        elif [[ -f "${SSL_SELF_SIGNED_DIR}/${PANEL_DOMAIN}.crt" ]]; then
            print_status "warning" "SSL certificate: Self-signed"
        else
            print_status "error" "SSL certificate: Not found"
            verification_errors+=("SSL certificate not found")
            all_ok=false
        fi
    fi
    
    # Verify database if installed
    if [[ "${INSTALL_MARIADB}" =~ ^[Yy]$ ]]; then
        if systemctl is-active --quiet mariadb 2>/dev/null || systemctl is-active --quiet mysql 2>/dev/null; then
            if command -v mysqladmin > /dev/null 2>&1; then
                if mysqladmin ping -h localhost --silent 2>/dev/null; then
                    print_status "success" "MariaDB: Running and responding"
                else
                    print_status "warning" "MariaDB: Running but not responding to ping"
                    verification_errors+=("MariaDB not responding")
                    all_ok=false
                fi
            else
                print_status "success" "MariaDB: Running"
            fi
        else
            print_status "error" "MariaDB: Not running"
            verification_errors+=("MariaDB not running")
            all_ok=false
        fi
    fi
    
    # Verify Redis if installed
    if [[ "${INSTALL_REDIS}" =~ ^[Yy]$ ]]; then
        if systemctl is-active --quiet redis 2>/dev/null || systemctl is-active --quiet redis-server 2>/dev/null; then
            if command -v redis-cli > /dev/null 2>&1; then
                if redis-cli ping > /dev/null 2>&1; then
                    print_status "success" "Redis: Running and responding"
                else
                    print_status "warning" "Redis: Running but not responding to ping"
                    verification_errors+=("Redis not responding")
                    all_ok=false
                fi
            else
                print_status "success" "Redis: Running"
            fi
        else
            print_status "error" "Redis: Not running"
            verification_errors+=("Redis not running")
            all_ok=false
        fi
    fi
    
    # Report final verification status
    if [[ "${all_ok}" == true ]]; then
        print_status "success" "All verification checks passed"
        return 0
    else
        print_status "warning" "Verification completed with ${#verification_errors[@]} issues"
        
        for error in "${verification_errors[@]}"; do
            echo -e "  ${YELLOW}•${NC} ${error}"
        done
        
        return 1
    fi
}

# ============================================================================
# SYSTEM INFORMATION LOGGING
# ============================================================================

log_system_info() {
    log_info "========== SYSTEM INFORMATION =========="
    log_info "Installer Version: ${INSTALLER_VERSION}"
    log_info "OS: $(uname -s) $(uname -r)"
    log_info "Kernel: $(uname -r)"
    log_info "Architecture: $(uname -m)"
    log_info "Hostname: $(hostname)"
    log_info "Date: $(date)"
    log_info "Memory: $(free -h | awk '/^Mem:/{print $2}')"
    log_info "CPU Cores: $(nproc)"
    log_info "Disk: $(df -h / | awk 'NR==2 {print $2 " total, " $4 " available"}')"
    log_info "Install Directory: ${INSTALL_DIR}"
    log_info "Log File: ${LOG_FILE}"
    log_info "========================================="
}

# ============================================================================
# INSTALLATION SUMMARY
# ============================================================================

display_installation_summary() {
    local os_version=""
    local node_version=""
    local mariadb_version=""
    local redis_version=""
    local verification_result="${1:-Unknown}"
    
    # Get OS version
    if [[ -f /etc/os-release ]]; then
        os_version=$(grep "^PRETTY_NAME=" /etc/os-release | cut -d'=' -f2 | tr -d '"')
    fi
    
    # Get Node.js version
    if command -v node > /dev/null 2>&1; then
        node_version=$(node --version 2>/dev/null || echo "Unknown")
    fi
    
    # Get MariaDB version
    if command -v mysql > /dev/null 2>&1; then
        mariadb_version=$(mysql --version 2>/dev/null | awk '{print $3}' | cut -d',' -f1 || echo "Unknown")
    fi
    
    # Get Redis version
    if command -v redis-server > /dev/null 2>&1; then
        redis_version=$(redis-server --version 2>/dev/null | awk '{print $3}' | cut -d'=' -f2 || echo "Unknown")
    fi
    
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${WHITE}        INSTALLATION SUMMARY${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo -e "${CYAN}System:${NC} ${WHITE}${os_version:-Unknown}${NC}"
    echo -e "${CYAN}Node.js:${NC} ${WHITE}${node_version:-Not installed}${NC}"
    echo -e "${CYAN}MariaDB:${NC} ${WHITE}${mariadb_version:-Not installed}${NC}"
    echo -e "${CYAN}Redis:${NC} ${WHITE}${redis_version:-Not installed}${NC}"
    echo -e "${CYAN}Panel URL:${NC} ${WHITE}https://${PANEL_DOMAIN}${NC}"
    echo -e "${CYAN}Username:${NC} ${WHITE}${ADMIN_USERNAME}${NC}"
    echo -e "${CYAN}Elapsed Time:${NC} ${WHITE}${ELAPSED_MINUTES}m ${ELAPSED_SECONDS}s${NC}"
    echo -e "${CYAN}Install Directory:${NC} ${WHITE}${INSTALL_DIR}${NC}"
    echo -e "${CYAN}Log File:${NC} ${WHITE}${LOG_FILE}${NC}"
    echo ""
    
    echo -e "${CYAN}Components Installed:${NC}"
    [[ "${INSTALL_MARIADB}" =~ ^[Yy]$ ]] && echo -e "  ${GREEN}✓${NC} MariaDB" || echo -e "  ${YELLOW}○${NC} MariaDB (skipped)"
    [[ "${INSTALL_REDIS}" =~ ^[Yy]$ ]] && echo -e "  ${GREEN}✓${NC} Redis" || echo -e "  ${YELLOW}○${NC} Redis (skipped)"
    [[ "${INSTALL_NGINX}" =~ ^[Yy]$ ]] && echo -e "  ${GREEN}✓${NC} Nginx" || echo -e "  ${YELLOW}○${NC} Nginx (skipped)"
    [[ "${INSTALL_SSL}" =~ ^[Yy]$ ]] && echo -e "  ${GREEN}✓${NC} SSL (Let's Encrypt)" || echo -e "  ${YELLOW}○${NC} SSL (skipped)"
    echo ""
    
    echo -e "${CYAN}Verification Result:${NC} ${WHITE}${verification_result}${NC}"
    echo -e "${GREEN}========================================${NC}"
}

# ============================================================================
# MAIN INSTALLATION
# ============================================================================

main() {
    local total_steps
    local current_step=0
    local step_result=0
    local verification_status=""
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)
                DRY_RUN="true"
                shift
                ;;
            --resume)
                RESUME="true"
                shift
                ;;
            --non-interactive)
                NON_INTERACTIVE="true"
                shift
                ;;
            --config)
                if [[ -f "$2" ]]; then
                    # shellcheck source=/dev/null
                    source "$2"
                    # Validate config immediately
                    if ! validate_config_variables; then
                        exit 1
                    fi
                    shift 2
                else
                    echo "Config file not found: $2"
                    exit 1
                fi
                ;;
            --help)
                echo "Usage: $0 [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  --dry-run              Show what would be installed without making changes"
                echo "  --resume               Resume from the last successful step"
                echo "  --non-interactive      Run without user interaction (use environment variables)"
                echo "  --config FILE          Load configuration from FILE"
                echo "  --help                 Show this help message"
                echo ""
                echo "Environment variables for non-interactive mode:"
                echo "  PANEL_DOMAIN           Panel domain name"
                echo "  ADMIN_EMAIL            Admin email address"
                echo "  ADMIN_USERNAME         Admin username"
                echo "  ADMIN_PASSWORD         Admin password"
                echo "  INSTALL_MARIADB        Install MariaDB [Y/n]"
                echo "  INSTALL_REDIS          Install Redis [Y/n]"
                echo "  INSTALL_NGINX          Install Nginx [Y/n]"
                echo "  INSTALL_SSL            Install SSL [Y/n]"
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
    
    # Record start time
    INSTALLATION_START_TIME=$(date +%s)
    
    # Initialize log directory
    mkdir -p "${LOG_DIR}" 2>/dev/null || true
    touch "${LOG_FILE}"
    chmod 644 "${LOG_FILE}"
    
    # Log system information
    log_system_info
    
    # Display header
    display_header
    
    # Load installation state if resuming
    if [[ "${RESUME}" == "true" ]]; then
        if ! load_state; then
            print_status "warning" "No previous installation state found. Starting fresh."
            RESUME="false"
        fi
    fi
    
    # Load all modules
    load_modules
    
    # Perform pre-flight checks
    pre_flight_checks
    
    # Collect user input (skip if resuming and config exists)
    if [[ "${RESUME}" == "true" ]] && [[ -f "${CONFIG_FILE}" ]]; then
        print_status "info" "Resuming installation with existing configuration"
        if ! load_config; then
            print_status "error" "Failed to load configuration for resume"
            exit 1
        fi
        # Ensure ADMIN_PASSWORD is set for resume (prompt if not)
        if [[ -z "${ADMIN_PASSWORD:-}" ]]; then
            print_status "warning" "ADMIN_PASSWORD not found. Please enter it to continue:"
            while true; do
                read -r -s -p "Admin Password: " ADMIN_PASSWORD
                echo ""
                if validate_password "${ADMIN_PASSWORD}"; then
                    break
                else
                    echo -e "${RED}Password must be at least 8 characters.${NC}"
                fi
            done
        fi
    else
        collect_user_input
        save_config
        load_config
    fi
    
    # Calculate total steps
    total_steps=$(calculate_total_steps)
    
    echo ""
    print_status "info" "Starting Codex Panel installation..."
    echo ""
    
    # Step 1: OS Detection
    ((current_step++))
    if ! execute_step "OS Detection" detect_os "os.sh" false "${current_step}" "${total_steps}"; then
        exit 1
    fi
    
    # Step 2: System Check
    ((current_step++))
    if ! execute_step "System Requirements" check_system_requirements "os.sh" false "${current_step}" "${total_steps}"; then
        exit 1
    fi
    
    # Step 3: Update System
    ((current_step++))
    if ! execute_step "System Update" update_system "packages.sh" false "${current_step}" "${total_steps}"; then
        exit 1
    fi
    
    # Step 4: Install Packages
    ((current_step++))
    if ! execute_step "Package Installation" install_required_packages "packages.sh" false "${current_step}" "${total_steps}"; then
        exit 1
    fi
    
    # Step 5: Install Node.js
    ((current_step++))
    if ! execute_step "Node.js Installation" install_node "node.sh" false "${current_step}" "${total_steps}"; then
        exit 1
    fi
    
    # Step 6: Install MariaDB (optional)
    if [[ "${INSTALL_MARIADB}" =~ ^[Yy]$ ]]; then
        ((current_step++))
        if ! execute_step "MariaDB Installation" install_mariadb "database.sh" false "${current_step}" "${total_steps}"; then
            exit 1
        fi
    else
        print_status "info" "Skipping MariaDB installation as requested"
    fi
    
    # Step 7: Install Redis (optional)
    if [[ "${INSTALL_REDIS}" =~ ^[Yy]$ ]]; then
        ((current_step++))
        if ! execute_step "Redis Installation" install_redis "database.sh" false "${current_step}" "${total_steps}"; then
            exit 1
        fi
    else
        print_status "info" "Skipping Redis installation as requested"
    fi
    
    # Step 8: Setup Backend
    ((current_step++))
    if ! execute_step "Backend Setup" install_backend "backend.sh" false "${current_step}" "${total_steps}"; then
        INSTALLATION_PARTIAL=true
        exit 1
    fi
    
    # Step 9: Setup Frontend
    ((current_step++))
    if ! execute_step "Frontend Setup" install_frontend "frontend.sh" false "${current_step}" "${total_steps}"; then
        INSTALLATION_PARTIAL=true
        exit 1
    fi
    
    # Step 10: Configure Nginx (optional)
    if [[ "${INSTALL_NGINX}" =~ ^[Yy]$ ]]; then
        ((current_step++))
        if ! execute_step "Nginx Configuration" setup_nginx "nginx.sh" false "${current_step}" "${total_steps}"; then
            INSTALLATION_PARTIAL=true
            exit 1
        fi
    else
        print_status "info" "Skipping Nginx configuration as requested"
    fi
    
    # Step 11: Setup SSL (optional)
    if [[ "${INSTALL_SSL}" =~ ^[Yy]$ ]]; then
        ((current_step++))
        if ! execute_step "SSL Setup" setup_ssl "ssl.sh" false "${current_step}" "${total_steps}"; then
            INSTALLATION_PARTIAL=true
            exit 1
        fi
    else
        print_status "info" "Skipping SSL setup as requested"
    fi
    
    # Step 12: Setup Service
    ((current_step++))
    if ! execute_step "Service Setup" setup_service "service.sh" false "${current_step}" "${total_steps}"; then
        INSTALLATION_PARTIAL=true
        exit 1
    fi
    
    # Step 13: Finish Installation
    ((current_step++))
    if ! execute_step "Finalization" finish_installation "finish.sh" false "${current_step}" "${total_steps}"; then
        INSTALLATION_PARTIAL=true
        exit 1
    fi
    
    # Run final verification AFTER finish_installation completes
    if final_verification; then
        step_result=0
        verification_status="PASSED"
    else
        step_result=1
        verification_status="WARNINGS"
    fi
    
    # Record end time AFTER all steps complete
    INSTALLATION_END_TIME=$(date +%s)
    local elapsed_time=$((INSTALLATION_END_TIME - INSTALLATION_START_TIME))
    ELAPSED_MINUTES=$((elapsed_time / 60))
    ELAPSED_SECONDS=$((elapsed_time % 60))
    
    # Log completion
    log_info "Installation completed in ${ELAPSED_MINUTES}m ${ELAPSED_SECONDS}s"
    
    # Clear sensitive data from memory
    ADMIN_PASSWORD=""
    ADMIN_PASSWORD_CONFIRM=""
    
    # Clean up state on successful completion
    cleanup_state
    
    # Display installation summary
    display_installation_summary "${verification_status}"
    
    if [[ ${step_result} -ne 0 ]]; then
        print_status "warning" "Installation completed with verification warnings"
        return 1
    fi
    
    print_status "success" "Installation completed successfully!"
    return 0
}

# ============================================================================
# EXECUTION
# ============================================================================

# Run main installation
main "$@"

# Exit with success
exit 0