#!/bin/bash
# Codex Panel - Systemd Service Management Module
# This file handles the Codex Panel backend systemd service installation and management

set -e

# Service configuration
SERVICE_NAME="codex-backend"
SERVICE_TEMPLATE="${INSTALL_DIR}/installer/services/codex-backend.service"
SERVICE_DEST="/etc/systemd/system/${SERVICE_NAME}.service"
BACKEND_DIR="${INSTALL_DIR}/backend"
SERVICE_USER="www-data"
SERVICE_GROUP="www-data"
SERVICE_BACKUP_DIR="/tmp/codexpanel-service-backup"

# Function to backup existing service
backup_service() {
    print_status "step" "Backing up existing service configuration..."
    
    # Check if service file exists
    if [[ ! -f "$SERVICE_DEST" ]]; then
        print_status "info" "No existing service file found, skipping backup"
        return 0
    fi
    
    # Create backup directory
    mkdir -p "$SERVICE_BACKUP_DIR"
    
    # Create backup timestamp
    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_path="${SERVICE_BACKUP_DIR}/${SERVICE_NAME}.service.${timestamp}"
    
    # Backup service file
    if cp "$SERVICE_DEST" "$backup_path"; then
        print_status "success" "Service backed up to: $backup_path"
        echo "$backup_path" > /tmp/codexpanel-service-backup-path
        return 0
    else
        print_status "error" "Failed to backup service file"
        return 1
    fi
}

# Function to install service
install_service() {
    print_status "step" "Installing systemd service..."
    
    # Verify template exists
    if [[ ! -f "$SERVICE_TEMPLATE" ]]; then
        print_status "error" "Service template not found: $SERVICE_TEMPLATE"
        return 1
    fi
    
    # Verify backend directory exists
    if [[ ! -d "$BACKEND_DIR" ]]; then
        print_status "error" "Backend directory not found: $BACKEND_DIR"
        return 1
    fi
    
    # Verify Node.js exists
    if ! command_exists node; then
        print_status "error" "Node.js not found. Please install Node.js first."
        return 1
    fi
    
    # Get Node.js path
    local node_path
    node_path=$(which node)
    
    # Get backend main file
    local main_file="${BACKEND_DIR}/dist/index.js"
    if [[ ! -f "$main_file" ]]; then
        print_status "error" "Backend main file not found: $main_file"
        return 1
    fi
    
    # Create service file from template with variable substitution
    print_status "info" "Generating service file from template..."
    
    # Read template and replace variables
    sed -e "s|{{SERVICE_NAME}}|${SERVICE_NAME}|g" \
        -e "s|{{BACKEND_DIR}}|${BACKEND_DIR}|g" \
        -e "s|{{SERVICE_USER}}|${SERVICE_USER}|g" \
        -e "s|{{SERVICE_GROUP}}|${SERVICE_GROUP}|g" \
        -e "s|{{NODE_PATH}}|${node_path}|g" \
        -e "s|{{MAIN_FILE}}|${main_file}|g" \
        "$SERVICE_TEMPLATE" > "$SERVICE_DEST"
    
    if [[ $? -ne 0 ]]; then
        print_status "error" "Failed to generate service file"
        return 1
    fi
    
    # Set proper permissions
    chmod 644 "$SERVICE_DEST"
    
    # Verify service file was created
    if [[ ! -f "$SERVICE_DEST" ]]; then
        print_status "error" "Service file not created: $SERVICE_DEST"
        return 1
    fi
    
    print_status "success" "Service file installed: $SERVICE_DEST"
    
    # Reload systemd
    print_status "info" "Reloading systemd daemon..."
    systemctl daemon-reload
    
    if [[ $? -ne 0 ]]; then
        print_status "error" "Failed to reload systemd daemon"
        return 1
    fi
    
    print_status "success" "Systemd daemon reloaded"
    return 0
}

# Function to enable service
enable_service() {
    print_status "step" "Enabling service on boot..."
    
    # Check if service file exists
    if [[ ! -f "$SERVICE_DEST" ]]; then
        print_status "error" "Service file not found: $SERVICE_DEST"
        return 1
    fi
    
    # Enable service
    if systemctl enable "$SERVICE_NAME" >> "$LOG_FILE" 2>&1; then
        print_status "success" "Service enabled successfully"
        return 0
    else
        print_status "error" "Failed to enable service"
        return 1
    fi
}

# Function to start service
start_service() {
    print_status "step" "Starting service..."
    
    # Check if service file exists
    if [[ ! -f "$SERVICE_DEST" ]]; then
        print_status "error" "Service file not found: $SERVICE_DEST"
        return 1
    fi
    
    # Start service
    if systemctl start "$SERVICE_NAME" >> "$LOG_FILE" 2>&1; then
        print_status "success" "Service started successfully"
        
        # Wait a moment for service to initialize
        sleep 3
        
        # Verify service is active
        if systemctl is-active --quiet "$SERVICE_NAME"; then
            print_status "success" "Service is running"
            return 0
        else
            print_status "error" "Service failed to start properly"
            
            # Show service status for debugging
            print_status "info" "Service status:"
            systemctl status "$SERVICE_NAME" --no-pager | head -20 | while IFS= read -r line; do
                echo -e "${YELLOW}  $line${NC}"
            done
            
            return 1
        fi
    else
        print_status "error" "Failed to start service"
        
        # Show service status for debugging
        print_status "info" "Service status:"
        systemctl status "$SERVICE_NAME" --no-pager | head -20 | while IFS= read -r line; do
            echo -e "${YELLOW}  $line${NC}"
        done
        
        return 1
    fi
}

# Function to restart service
restart_service() {
    print_status "step" "Restarting service..."
    
    # Check if service file exists
    if [[ ! -f "$SERVICE_DEST" ]]; then
        print_status "error" "Service file not found: $SERVICE_DEST"
        return 1
    fi
    
    # Check if service is running
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        print_status "info" "Service is running, restarting..."
    else
        print_status "info" "Service is not running, starting..."
    fi
    
    # Restart service
    if systemctl restart "$SERVICE_NAME" >> "$LOG_FILE" 2>&1; then
        print_status "success" "Service restarted successfully"
        
        # Wait a moment for service to initialize
        sleep 3
        
        # Verify service is active
        if systemctl is-active --quiet "$SERVICE_NAME"; then
            print_status "success" "Service is running"
            return 0
        else
            print_status "error" "Service failed to restart properly"
            return 1
        fi
    else
        print_status "error" "Failed to restart service"
        return 1
    fi
}

# Function to stop service
stop_service() {
    print_status "step" "Stopping service..."
    
    # Check if service file exists
    if [[ ! -f "$SERVICE_DEST" ]]; then
        print_status "info" "Service file not found, nothing to stop"
        return 0
    fi
    
    # Check if service is running
    if ! systemctl is-active --quiet "$SERVICE_NAME"; then
        print_status "info" "Service is already stopped"
        return 0
    fi
    
    # Stop service
    if systemctl stop "$SERVICE_NAME" >> "$LOG_FILE" 2>&1; then
        print_status "success" "Service stopped successfully"
        return 0
    else
        print_status "error" "Failed to stop service"
        return 1
    fi
}

# Function to verify service
verify_service() {
    print_status "step" "Verifying service..."
    
    local verification_failed=false
    
    # Verify service file exists
    if [[ ! -f "$SERVICE_DEST" ]]; then
        print_status "error" "Service file not found: $SERVICE_DEST"
        verification_failed=true
    else
        print_status "success" "Service file exists"
    fi
    
    # Verify service is enabled
    if systemctl is-enabled --quiet "$SERVICE_NAME" 2>/dev/null; then
        print_status "success" "Service is enabled"
    else
        print_status "warning" "Service is not enabled"
        verification_failed=true
    fi
    
    # Verify service is active
    if systemctl is-active --quiet "$SERVICE_NAME" 2>/dev/null; then
        print_status "success" "Service is active"
    else
        print_status "error" "Service is not active"
        verification_failed=true
        
        # Show service status for debugging
        print_status "info" "Service status:"
        systemctl status "$SERVICE_NAME" --no-pager | head -20 | while IFS= read -r line; do
            echo -e "${YELLOW}  $line${NC}"
        done
        
        # Show recent logs
        print_status "info" "Recent journal entries:"
        journalctl -u "$SERVICE_NAME" -n 10 --no-pager | while IFS= read -r line; do
            echo -e "${YELLOW}  $line${NC}"
        done
    fi
    
    # Verify backend directory exists
    if [[ -d "$BACKEND_DIR" ]]; then
        print_status "success" "Backend directory exists"
    else
        print_status "error" "Backend directory not found: $BACKEND_DIR"
        verification_failed=true
    fi
    
    # Verify Node.js exists
    if command_exists node; then
        print_status "success" "Node.js is installed"
    else
        print_status "error" "Node.js not found"
        verification_failed=true
    fi
    
    # Verify main file exists
    if [[ -f "$BACKEND_DIR/dist/index.js" ]]; then
        print_status "success" "Backend main file exists"
    else
        print_status "error" "Backend main file not found: $BACKEND_DIR/dist/index.js"
        verification_failed=true
    fi
    
    # Check for fatal startup errors in journal
    if journalctl -u "$SERVICE_NAME" -n 5 --no-pager 2>/dev/null | grep -qi "error\|fatal\|exception"; then
        print_status "warning" "Recent errors found in service logs"
        print_status "info" "Last 5 journal entries:"
        journalctl -u "$SERVICE_NAME" -n 5 --no-pager | while IFS= read -r line; do
            echo -e "${YELLOW}  $line${NC}"
        done
    fi
    
    if [[ "$verification_failed" == true ]]; then
        print_status "error" "Service verification failed"
        return 1
    else
        print_status "success" "Service verification passed"
        return 0
    fi
}

# Function to rollback service
rollback_service() {
    print_status "step" "Rolling back service configuration..."
    
    # Get backup path
    local backup_path
    if [[ -f /tmp/codexpanel-service-backup-path ]]; then
        backup_path=$(cat /tmp/codexpanel-service-backup-path)
        rm -f /tmp/codexpanel-service-backup-path
    else
        # Find latest backup
        backup_path=$(ls -td "${SERVICE_BACKUP_DIR}/${SERVICE_NAME}.service."* 2>/dev/null | head -1)
    fi
    
    # Verify backup exists
    if [[ -z "$backup_path" ]] || [[ ! -f "$backup_path" ]]; then
        print_status "warning" "No backup found, attempting to remove service"
        
        # Remove current service file
        if [[ -f "$SERVICE_DEST" ]]; then
            rm -f "$SERVICE_DEST"
            systemctl daemon-reload
            print_status "info" "Removed service file"
        fi
        
        return 0
    fi
    
    print_status "info" "Restoring service from backup: $backup_path"
    
    # Restore backup
    if cp "$backup_path" "$SERVICE_DEST"; then
        chmod 644 "$SERVICE_DEST"
        systemctl daemon-reload
        
        # Try to restart service if it was running
        if systemctl is-enabled --quiet "$SERVICE_NAME" 2>/dev/null; then
            systemctl restart "$SERVICE_NAME" >> "$LOG_FILE" 2>&1
            print_status "info" "Service restarted from backup"
        fi
        
        print_status "success" "Service rollback completed successfully"
        return 0
    else
        print_status "error" "Failed to restore service backup"
        return 1
    fi
}

# Function to setup service (main entry point)
setup_service() {
    print_status "step" "Setting up systemd service..."
    
    local backup_path=""
    
    # Backup existing service
    if [[ -f "$SERVICE_DEST" ]]; then
        if ! backup_service; then
            print_status "warning" "Failed to backup service, continuing..."
        fi
        backup_path=$(cat /tmp/codexpanel-service-backup-path 2>/dev/null || echo "")
    fi
    
    # Install service
    if ! install_service; then
        print_status "error" "Failed to install service"
        rollback_service
        return 1
    fi
    
    # Enable service
    if ! enable_service; then
        print_status "error" "Failed to enable service"
        rollback_service
        return 1
    fi
    
    # Start service
    if ! start_service; then
        print_status "error" "Failed to start service"
        rollback_service
        return 1
    fi
    
    # Verify service
    if verify_service; then
        print_status "success" "Service setup completed successfully"
        
        # Clean up backup if successful
        if [[ -n "$backup_path" ]] && [[ -f "$backup_path" ]]; then
            print_status "info" "Cleaning up backup: $backup_path"
            rm -f "$backup_path" 2>/dev/null || true
            rm -f /tmp/codexpanel-service-backup-path 2>/dev/null || true
        fi
        
        return 0
    else
        print_status "error" "Service verification failed"
        rollback_service
        return 1
    fi
}

# Export functions
export -f backup_service
export -f install_service
export -f enable_service
export -f start_service
export -f restart_service
export -f stop_service
export -f verify_service
export -f rollback_service
export -f setup_service

# Export variables
export SERVICE_NAME
export SERVICE_TEMPLATE
export SERVICE_DEST
export BACKEND_DIR
export SERVICE_USER
export SERVICE_GROUP
export SERVICE_BACKUP_DIR