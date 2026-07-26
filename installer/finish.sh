#!/bin/bash
# Codex Panel - Installation Finish Module
# This file handles final verification, cleanup, and installation summary

set -e

# Finish configuration
FINISH_LOG_DIR="${LOG_DIR}"
FINISH_TEMP_DIR="/tmp/codexpanel"
FINISH_INSTALL_MARKER="${INSTALL_DIR}/.installed"
FINISH_VERSION_FILE="${INSTALL_DIR}/.version"

# Function to verify all services
verify_all_services() {
    print_status "step" "Verifying all services..."
    
    local services_ok=true
    
    # Check Nginx
    if command_exists nginx; then
        if systemctl is-active --quiet nginx 2>/dev/null; then
            print_status "success" "Nginx: Running"
        else
            print_status "error" "Nginx: Not running"
            services_ok=false
        fi
    else
        print_status "warning" "Nginx: Not installed"
    fi
    
    # Check MariaDB
    if command_exists mysql; then
        if systemctl is-active --quiet mariadb 2>/dev/null || systemctl is-active --quiet mysql 2>/dev/null; then
            print_status "success" "MariaDB: Running"
        else
            print_status "error" "MariaDB: Not running"
            services_ok=false
        fi
    else
        print_status "warning" "MariaDB: Not installed"
    fi
    
    # Check Redis
    if command_exists redis-server; then
        if systemctl is-active --quiet redis 2>/dev/null || systemctl is-active --quiet redis-server 2>/dev/null; then
            print_status "success" "Redis: Running"
        else
            print_status "warning" "Redis: Not running"
        fi
    else
        print_status "warning" "Redis: Not installed"
    fi
    
    # Check Codex Panel Backend
    if systemctl is-active --quiet codex-backend 2>/dev/null; then
        print_status "success" "Codex Backend: Running"
    else
        print_status "error" "Codex Backend: Not running"
        services_ok=false
    fi
    
    # Check PM2 processes
    if command_exists pm2; then
        local pm2_count
        pm2_count=$(pm2 list | grep -c "online" 2>/dev/null || echo "0")
        if [[ "$pm2_count" -gt 0 ]]; then
            print_status "success" "PM2: $pm2_count processes running"
        else
            print_status "warning" "PM2: No processes running"
        fi
    fi
    
    if [[ "$services_ok" == true ]]; then
        print_status "success" "All services are running properly"
        return 0
    else
        print_status "warning" "Some services are not running as expected"
        return 1
    fi
}

# Function to test backend API
test_backend_api() {
    print_status "step" "Testing backend API..."
    
    local api_url="http://localhost:3000/health"
    local response
    local http_code
    
    # Wait for backend to be ready
    local max_attempts=10
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        response=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "$api_url" 2>/dev/null || echo "000")
        
        if [[ "$response" == "200" ]]; then
            print_status "success" "Backend API is responding (HTTP 200)"
            return 0
        fi
        
        print_status "info" "Waiting for backend API... (attempt $attempt/$max_attempts)"
        sleep 2
        ((attempt++))
    done
    
    print_status "warning" "Backend API is not responding (HTTP $response)"
    return 1
}

# Function to test frontend
test_frontend() {
    print_status "step" "Testing frontend deployment..."
    
    local frontend_url="https://${PANEL_DOMAIN}"
    local response
    
    # Try to access frontend
    response=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 --max-time 10 "$frontend_url" 2>/dev/null || echo "000")
    
    if [[ "$response" == "200" ]] || [[ "$response" == "301" ]] || [[ "$response" == "302" ]]; then
        print_status "success" "Frontend is accessible (HTTP $response)"
        return 0
    else
        print_status "warning" "Frontend is not accessible (HTTP $response)"
        return 1
    fi
}

# Function to display installation summary
display_summary() {
    print_status "step" "Generating installation summary..."
    
    echo ""
    echo -e "${GREEN}======================================${NC}"
    echo -e "${WHITE}      CODEX PANEL INSTALLATION${NC}"
    echo -e "${GREEN}======================================${NC}"
    echo ""
    
    # Panel access
    echo -e "${CYAN}Panel Access:${NC}"
    echo -e "  URL: ${WHITE}https://${PANEL_DOMAIN}${NC}"
    echo -e "  Username: ${WHITE}${ADMIN_USERNAME}${NC}"
    echo -e "  Password: ${WHITE}${ADMIN_PASSWORD}${NC}"
    echo ""
    
    # Database
    if [[ -f /root/.codexpanel_db_password ]]; then
        echo -e "${CYAN}Database:${NC}"
        echo -e "  Database: ${WHITE}${DB_NAME}${NC}"
        echo -e "  Username: ${WHITE}${DB_USER}${NC}"
        echo -e "  Password: ${WHITE}${DB_PASSWORD}${NC}"
        echo -e "  Credentials saved in: ${WHITE}/root/.codexpanel_db_password${NC}"
        echo ""
    fi
    
    # MariaDB root
    if [[ -f /root/.mariadb_root_password ]]; then
        echo -e "${CYAN}MariaDB Root:${NC}"
        echo -e "  Password: ${WHITE}$(cat /root/.mariadb_root_password)${NC}"
        echo -e "  Credentials saved in: ${WHITE}/root/.mariadb_root_password${NC}"
        echo ""
    fi
    
    # Services
    echo -e "${CYAN}Services Status:${NC}"
    
    if systemctl is-active --quiet nginx 2>/dev/null; then
        echo -e "  ${GREEN}✓${NC} Nginx: Running"
    else
        echo -e "  ${RED}✗${NC} Nginx: Not running"
    fi
    
    if systemctl is-active --quiet mariadb 2>/dev/null || systemctl is-active --quiet mysql 2>/dev/null; then
        echo -e "  ${GREEN}✓${NC} MariaDB: Running"
    else
        echo -e "  ${YELLOW}○${NC} MariaDB: Not running"
    fi
    
    if systemctl is-active --quiet codex-backend 2>/dev/null; then
        echo -e "  ${GREEN}✓${NC} Codex Backend: Running"
    else
        echo -e "  ${RED}✗${NC} Codex Backend: Not running"
    fi
    
    if systemctl is-active --quiet redis 2>/dev/null || systemctl is-active --quiet redis-server 2>/dev/null; then
        echo -e "  ${GREEN}✓${NC} Redis: Running"
    else
        echo -e "  ${YELLOW}○${NC} Redis: Not running"
    fi
    
    echo ""
    
    # SSL
    if [[ -f "${SSL_LIVE_DIR}/${PANEL_DOMAIN}/fullchain.pem" ]]; then
        echo -e "${CYAN}SSL Certificate:${NC}"
        echo -e "  Status: ${GREEN}Installed (Let's Encrypt)${NC}"
        local expiry_date
        expiry_date=$(openssl x509 -in "${SSL_LIVE_DIR}/${PANEL_DOMAIN}/fullchain.pem" -enddate -noout 2>/dev/null | cut -d'=' -f2 || echo "Unknown")
        echo -e "  Expires: ${WHITE}${expiry_date}${NC}"
        echo ""
    elif [[ -f "${SSL_SELF_SIGNED_DIR}/${PANEL_DOMAIN}.crt" ]]; then
        echo -e "${CYAN}SSL Certificate:${NC}"
        echo -e "  Status: ${YELLOW}Self-signed (Not trusted by browsers)${NC}"
        echo ""
    fi
    
    # Installation paths
    echo -e "${CYAN}Installation Paths:${NC}"
    echo -e "  Install Directory: ${WHITE}${INSTALL_DIR}${NC}"
    echo -e "  Backend: ${WHITE}${BACKEND_DIR}${NC}"
    echo -e "  Frontend: ${WHITE}${FRONTEND_DEPLOY_DIR}${NC}"
    echo -e "  Logs: ${WHITE}${FINISH_LOG_DIR}${NC}"
    echo ""
    
    # Log files
    echo -e "${CYAN}Log Files:${NC}"
    echo -e "  Install Log: ${WHITE}${LOG_FILE}${NC}"
    echo -e "  Backend Log: ${WHITE}${FINISH_LOG_DIR}/backend.log${NC}"
    echo -e "  Nginx Access: ${WHITE}/var/log/nginx/access.log${NC}"
    echo -e "  Nginx Error: ${WHITE}/var/log/nginx/error.log${NC}"
    echo ""
    
    # Management commands
    echo -e "${CYAN}Management Commands:${NC}"
    echo -e "  Start backend: ${WHITE}systemctl start codex-backend${NC}"
    echo -e "  Stop backend: ${WHITE}systemctl stop codex-backend${NC}"
    echo -e "  Restart backend: ${WHITE}systemctl restart codex-backend${NC}"
    echo -e "  View backend logs: ${WHITE}journalctl -u codex-backend -f${NC}"
    echo -e "  View install logs: ${WHITE}tail -f ${LOG_FILE}${NC}"
    echo ""
    
    # PM2 commands
    if command_exists pm2; then
        echo -e "${CYAN}PM2 Commands:${NC}"
        echo -e "  List processes: ${WHITE}pm2 list${NC}"
        echo -e "  Monitor: ${WHITE}pm2 monit${NC}"
        echo -e "  View logs: ${WHITE}pm2 logs${NC}"
        echo ""
    fi
    
    # Next steps
    echo -e "${CYAN}Next Steps:${NC}"
    echo -e "  1. Access your panel at ${WHITE}https://${PANEL_DOMAIN}${NC}"
    echo -e "  2. Log in with the credentials provided above"
    echo -e "  3. Configure your first website"
    echo -e "  4. Review security settings"
    echo ""
    
    echo -e "${GREEN}======================================${NC}"
    echo -e "${WHITE}      Installation Complete!${NC}"
    echo -e "${GREEN}======================================${NC}"
    echo ""
}

# Function to clean temporary files
cleanup_temp_files() {
    print_status "step" "Cleaning up temporary files..."
    
    local cleaned=false
    
    # Clean up backup files
    if [[ -d "$SERVICE_BACKUP_DIR" ]]; then
        rm -rf "${SERVICE_BACKUP_DIR}"/*.service.* 2>/dev/null || true
        print_status "info" "Cleaned service backups"
        cleaned=true
    fi
    
    # Clean up frontend backups
    if [[ -d "${FRONTEND_BACKUP_DIR}" ]]; then
        rm -rf "${FRONTEND_BACKUP_DIR}"_* 2>/dev/null || true
        print_status "info" "Cleaned frontend backups"
        cleaned=true
    fi
    
    # Clean up temporary backup markers
    rm -f /tmp/codexpanel-*.backup-path 2>/dev/null || true
    
    # Clean up temporary SSL backups
    if [[ -d "/tmp/ssl-backup-${PANEL_DOMAIN}"* ]]; then
        rm -rf "/tmp/ssl-backup-${PANEL_DOMAIN}"* 2>/dev/null || true
        print_status "info" "Cleaned SSL backups"
        cleaned=true
    fi
    
    # Clean up npm cache if it exists
    if [[ -d "${HOME}/.npm/_cacache" ]] || [[ -d "/root/.npm/_cacache" ]]; then
        print_status "info" "Cleaning npm cache..."
        npm cache clean --force >> "$LOG_FILE" 2>&1 || true
        cleaned=true
    fi
    
    # Clean up temporary build files
    if [[ -d "${FRONTEND_DIR}/node_modules/.cache" ]]; then
        rm -rf "${FRONTEND_DIR}/node_modules/.cache" 2>/dev/null || true
        print_status "info" "Cleaned frontend cache"
        cleaned=true
    fi
    
    # Remove temporary log file if empty
    if [[ -f "$LOG_FILE" ]] && [[ ! -s "$LOG_FILE" ]]; then
        rm -f "$LOG_FILE" 2>/dev/null || true
    fi
    
    if [[ "$cleaned" == true ]]; then
        print_status "success" "Temporary files cleaned"
    else
        print_status "info" "No temporary files to clean"
    fi
}

# Function to create installation marker
create_installation_marker() {
    print_status "step" "Creating installation marker..."
    
    # Create marker file
    cat > "$FINISH_INSTALL_MARKER" <<EOF
# Codex Panel Installation Marker
# This file indicates that Codex Panel has been installed
# Do not delete this file unless you want to reinstall

Installation Date: $(date)
Installation Time: $(date +%Y-%m-%d_%H-%M-%S)
Panel Domain: ${PANEL_DOMAIN}
Admin Username: ${ADMIN_USERNAME}
Installation Directory: ${INSTALL_DIR}
Backend Directory: ${BACKEND_DIR}
Frontend Directory: ${FRONTEND_DEPLOY_DIR}
Database: ${DB_NAME}
Database User: ${DB_USER}
EOF
    
    chmod 644 "$FINISH_INSTALL_MARKER"
    
    # Create version file
    echo "1.0.0" > "$FINISH_VERSION_FILE"
    chmod 644 "$FINISH_VERSION_FILE"
    
    print_status "success" "Installation marker created"
}

# Function to display system information
display_system_info() {
    print_status "step" "System Information:"
    echo ""
    
    local os_info
    if [[ -f /etc/os-release ]]; then
        os_info=$(grep "^PRETTY_NAME=" /etc/os-release | cut -d'=' -f2 | tr -d '"')
    else
        os_info="Unknown"
    fi
    
    echo -e "${CYAN}Operating System:${NC} ${WHITE}${os_info}${NC}"
    echo -e "${CYAN}Kernel Version:${NC} ${WHITE}$(uname -r)${NC}"
    echo -e "${CYAN}Architecture:${NC} ${WHITE}$(uname -m)${NC}"
    echo -e "${CYAN}CPU Cores:${NC} ${WHITE}$(nproc)${NC}"
    echo -e "${CYAN}Total RAM:${NC} ${WHITE}$(free -h | awk '/^Mem:/ {print $2}')${NC}"
    echo -e "${CYAN}Disk Usage:${NC} ${WHITE}$(df -h / | awk 'NR==2 {print $3 " used of " $2 " (" $5 ")"}')${NC}"
    echo -e "${CYAN}Server IP:${NC} ${WHITE}$(get_server_ip)${NC}"
    echo ""
}

# Function to perform final verification
final_verification() {
    print_status "step" "Performing final verification..."
    
    local all_ok=true
    
    # Verify services
    if ! verify_all_services; then
        all_ok=false
    fi
    
    # Test backend API
    if ! test_backend_api; then
        all_ok=false
    fi
    
    # Test frontend
    if ! test_frontend; then
        all_ok=false
    fi
    
    if [[ "$all_ok" == true ]]; then
        print_status "success" "All final verification checks passed"
        return 0
    else
        print_status "warning" "Some final verification checks failed"
        return 1
    fi
}

# Function to save installation summary to file
save_installation_summary() {
    print_status "step" "Saving installation summary..."
    
    local summary_file="${INSTALL_DIR}/installation-summary.txt"
    
    {
        echo "Codex Panel Installation Summary"
        echo "================================="
        echo "Installation Date: $(date)"
        echo "Installation Time: $(date +%Y-%m-%d_%H-%M-%S)"
        echo ""
        echo "Panel Access:"
        echo "  URL: https://${PANEL_DOMAIN}"
        echo "  Username: ${ADMIN_USERNAME}"
        echo "  Password: ${ADMIN_PASSWORD}"
        echo ""
        echo "Database:"
        echo "  Database: ${DB_NAME}"
        echo "  Username: ${DB_USER}"
        echo "  Password: ${DB_PASSWORD}"
        echo ""
        echo "Installation Paths:"
        echo "  Install Directory: ${INSTALL_DIR}"
        echo "  Backend: ${BACKEND_DIR}"
        echo "  Frontend: ${FRONTEND_DEPLOY_DIR}"
        echo "  Logs: ${FINISH_LOG_DIR}"
        echo ""
        echo "Log Files:"
        echo "  Install Log: ${LOG_FILE}"
        echo "  Backend Log: ${FINISH_LOG_DIR}/backend.log"
        echo ""
        echo "Management Commands:"
        echo "  Start backend: systemctl start codex-backend"
        echo "  Stop backend: systemctl stop codex-backend"
        echo "  Restart backend: systemctl restart codex-backend"
        echo "  View backend logs: journalctl -u codex-backend -f"
    } > "$summary_file"
    
    chmod 644 "$summary_file"
    print_status "success" "Installation summary saved to: $summary_file"
}

# Function to show post-installation tips
show_post_install_tips() {
    echo ""
    echo -e "${CYAN}Post-Installation Tips:${NC}"
    echo ""
    echo -e "  ${YELLOW}1.${NC} Secure your MariaDB installation:"
    echo -e "     ${WHITE}mysql_secure_installation${NC}"
    echo ""
    echo -e "  ${YELLOW}2.${NC} Configure firewall (if not already done):"
    echo -e "     ${WHITE}ufw allow 22/tcp${NC}"
    echo -e "     ${WHITE}ufw allow 80/tcp${NC}"
    echo -e "     ${WHITE}ufw allow 443/tcp${NC}"
    echo -e "     ${WHITE}ufw enable${NC}"
    echo ""
    echo -e "  ${YELLOW}3.${NC} Set up backups:"
    echo -e "     ${WHITE}Create a cron job to backup your database and files${NC}"
    echo ""
    echo -e "  ${YELLOW}4.${NC} Monitor your system:"
    echo -e "     ${WHITE}Install monitoring tools like Netdata or Prometheus${NC}"
    echo ""
    echo -e "  ${YELLOW}5.${NC} Regular updates:"
    echo -e "     ${WHITE}apt update && apt upgrade${NC}"
    echo -e "     ${WHITE}npm update -g${NC}"
    echo ""
    echo -e "  ${YELLOW}6.${NC} Check SSL certificate renewal:"
    echo -e "     ${WHITE}certbot renew --dry-run${NC}"
    echo ""
}

# Main finish function
finish_installation() {
    print_status "step" "Finalizing installation..."
    
    # Display system information
    display_system_info
    
    # Create installation marker
    create_installation_marker
    
    # Perform final verification
    final_verification || true
    
    # Clean up temporary files
    cleanup_temp_files
    
    # Save installation summary
    save_installation_summary
    
    # Display summary
    display_summary
    
    # Show post-installation tips
    show_post_install_tips
    
    # Export final status
    export INSTALLATION_COMPLETE="true"
    
    print_status "success" "Installation finalized successfully"
    return 0
}

# Export functions
export -f verify_all_services
export -f test_backend_api
export -f test_frontend
export -f display_summary
export -f cleanup_temp_files
export -f create_installation_marker
export -f display_system_info
export -f final_verification
export -f save_installation_summary
export -f show_post_install_tips
export -f finish_installation

# Export variables
export FINISH_LOG_DIR
export FINISH_TEMP_DIR
export FINISH_INSTALL_MARKER
export FINISH_VERSION_FILE