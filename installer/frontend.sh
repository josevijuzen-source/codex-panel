#!/bin/bash
# Codex Panel - Frontend Deployment Module
# This file handles React frontend installation, build, and deployment

set -e

# Frontend configuration
FRONTEND_DIR="${INSTALL_DIR}/frontend"
FRONTEND_BUILD_DIR="${FRONTEND_DIR}/dist"
FRONTEND_DEPLOY_DIR="/var/www/codexpanel/frontend"
FRONTEND_BACKUP_DIR="/tmp/codexpanel-frontend-backup"
FRONTEND_OWNER="codexpanel"
FRONTEND_GROUP="www-data"

# Function to install frontend dependencies
install_frontend_dependencies() {
    print_status "step" "Installing frontend dependencies..."
    
    # Verify Node.js is installed
    if ! command_exists node; then
        print_status "error" "Node.js is not installed. Please install Node.js first."
        return 1
    fi
    
    # Verify npm is installed
    if ! command_exists npm; then
        print_status "error" "npm is not installed. Please install npm first."
        return 1
    fi
    
    # Check if frontend directory exists
    if [[ ! -d "$FRONTEND_DIR" ]]; then
        print_status "error" "Frontend directory not found: $FRONTEND_DIR"
        return 1
    fi
    
    # Check if package.json exists
    if [[ ! -f "$FRONTEND_DIR/package.json" ]]; then
        print_status "error" "package.json not found in $FRONTEND_DIR"
        return 1
    fi
    
    cd "$FRONTEND_DIR"
    
    # Check for package-lock.json to use npm ci for faster, reliable installs
    if [[ -f "$FRONTEND_DIR/package-lock.json" ]]; then
        print_status "info" "Using npm ci for faster installation..."
        if npm ci >> "$LOG_FILE" 2>&1; then
            print_status "success" "Frontend dependencies installed using npm ci"
            return 0
        else
            print_status "warning" "npm ci failed, falling back to npm install..."
        fi
    fi
    
    # Fallback to npm install
    print_status "info" "Installing frontend dependencies with npm install..."
    if npm install >> "$LOG_FILE" 2>&1; then
        print_status "success" "Frontend dependencies installed successfully"
        return 0
    else
        print_status "error" "Failed to install frontend dependencies"
        return 1
    fi
}

# Function to build frontend
build_frontend() {
    print_status "step" "Building frontend application..."
    
    # Verify frontend directory exists
    if [[ ! -d "$FRONTEND_DIR" ]]; then
        print_status "error" "Frontend directory not found: $FRONTEND_DIR"
        return 1
    fi
    
    cd "$FRONTEND_DIR"
    
    # Check if build script exists in package.json
    if ! grep -q '"build"' package.json; then
        print_status "error" "Build script not found in package.json"
        return 1
    fi
    
    # Clean previous build if exists
    if [[ -d "$FRONTEND_BUILD_DIR" ]]; then
        print_status "info" "Removing previous build directory..."
        rm -rf "$FRONTEND_BUILD_DIR"
    fi
    
    # Run build
    print_status "info" "Running npm run build..."
    if npm run build >> "$LOG_FILE" 2>&1; then
        print_status "success" "Frontend build completed successfully"
    else
        print_status "error" "Frontend build failed"
        
        # Show last few lines of build output for debugging
        if [[ -f "$LOG_FILE" ]]; then
            print_status "info" "Last 20 lines of build log:"
            tail -20 "$LOG_FILE" | while IFS= read -r line; do
                echo -e "${YELLOW}  $line${NC}"
            done
        fi
        
        return 1
    fi
    
    # Verify build output
    if [[ ! -d "$FRONTEND_BUILD_DIR" ]]; then
        print_status "error" "Build directory not created: $FRONTEND_BUILD_DIR"
        return 1
    fi
    
    # Check for index.html
    if [[ ! -f "$FRONTEND_BUILD_DIR/index.html" ]]; then
        print_status "error" "Build failed: index.html not found"
        return 1
    fi
    
    print_status "success" "Frontend build verified"
    return 0
}

# Function to backup frontend
backup_frontend() {
    print_status "step" "Backing up existing frontend deployment..."
    
    # Check if deployment exists
    if [[ ! -d "$FRONTEND_DEPLOY_DIR" ]]; then
        print_status "info" "No existing frontend deployment found, skipping backup"
        return 0
    fi
    
    # Create backup timestamp
    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_path="${FRONTEND_BACKUP_DIR}_${timestamp}"
    
    # Create backup
    if rsync -a "$FRONTEND_DEPLOY_DIR/" "$backup_path/" 2>/dev/null; then
        print_status "success" "Frontend backed up to: $backup_path"
        echo "$backup_path" > /tmp/codexpanel-frontend-backup-path
        return 0
    else
        # Fallback to cp if rsync not available
        print_status "info" "rsync not available, using cp for backup..."
        if cp -a "$FRONTEND_DEPLOY_DIR" "$backup_path"; then
            print_status "success" "Frontend backed up to: $backup_path"
            echo "$backup_path" > /tmp/codexpanel-frontend-backup-path
            return 0
        else
            print_status "error" "Failed to backup frontend deployment"
            return 1
        fi
    fi
}

# Function to deploy frontend
deploy_frontend() {
    print_status "step" "Deploying frontend application..."
    
    # Verify build exists
    if [[ ! -d "$FRONTEND_BUILD_DIR" ]]; then
        print_status "error" "Build directory not found: $FRONTEND_BUILD_DIR"
        return 1
    fi
    
    # Verify build has content
    if [[ -z "$(ls -A "$FRONTEND_BUILD_DIR")" ]]; then
        print_status "error" "Build directory is empty"
        return 1
    fi
    
    # Create deployment directory if it doesn't exist
    create_directory "$FRONTEND_DEPLOY_DIR" "${FRONTEND_OWNER}:${FRONTEND_GROUP}" 755
    
    # Deploy using rsync if available
    if command_exists rsync; then
        print_status "info" "Using rsync for deployment..."
        if rsync -a --delete "$FRONTEND_BUILD_DIR/" "$FRONTEND_DEPLOY_DIR/" >> "$LOG_FILE" 2>&1; then
            print_status "success" "Frontend deployed successfully using rsync"
        else
            print_status "error" "rsync deployment failed"
            return 1
        fi
    else
        # Fallback to cp
        print_status "info" "Using cp for deployment..."
        
        # Remove old deployment
        rm -rf "${FRONTEND_DEPLOY_DIR:?}"/* 2>/dev/null || true
        
        # Copy new build
        if cp -a "$FRONTEND_BUILD_DIR"/* "$FRONTEND_DEPLOY_DIR/" >> "$LOG_FILE" 2>&1; then
            print_status "success" "Frontend deployed successfully using cp"
        else
            print_status "error" "cp deployment failed"
            return 1
        fi
    fi
    
    # Set proper permissions
    print_status "info" "Setting file permissions..."
    
    # Set directory permissions
    find "$FRONTEND_DEPLOY_DIR" -type d -exec chmod 755 {} \; >> "$LOG_FILE" 2>&1
    
    # Set file permissions
    find "$FRONTEND_DEPLOY_DIR" -type f -exec chmod 644 {} \; >> "$LOG_FILE" 2>&1
    
    # Set ownership
    chown -R "${FRONTEND_OWNER}:${FRONTEND_GROUP}" "$FRONTEND_DEPLOY_DIR" >> "$LOG_FILE" 2>&1
    
    print_status "success" "Permissions set correctly"
    return 0
}

# Function to rollback frontend
rollback_frontend() {
    print_status "step" "Rolling back frontend deployment..."
    
    # Check if backup path exists
    local backup_path
    if [[ -f /tmp/codexpanel-frontend-backup-path ]]; then
        backup_path=$(cat /tmp/codexpanel-frontend-backup-path)
        rm -f /tmp/codexpanel-frontend-backup-path
    else
        # Find latest backup
        backup_path=$(ls -td "${FRONTEND_BACKUP_DIR}"_* 2>/dev/null | head -1)
    fi
    
    # Verify backup exists
    if [[ -z "$backup_path" ]] || [[ ! -d "$backup_path" ]]; then
        print_status "warning" "No backup found, cannot rollback"
        return 1
    fi
    
    print_status "info" "Restoring from backup: $backup_path"
    
    # Remove current deployment
    rm -rf "$FRONTEND_DEPLOY_DIR"/* 2>/dev/null || true
    
    # Restore backup
    if rsync -a "$backup_path/" "$FRONTEND_DEPLOY_DIR/" 2>/dev/null; then
        print_status "success" "Frontend rollback completed successfully"
        return 0
    else
        # Fallback to cp
        if cp -a "$backup_path"/* "$FRONTEND_DEPLOY_DIR/" >> "$LOG_FILE" 2>&1; then
            print_status "success" "Frontend rollback completed successfully"
            return 0
        else
            print_status "error" "Failed to restore backup"
            return 1
        fi
    fi
}

# Function to verify frontend deployment
verify_frontend() {
    print_status "step" "Verifying frontend deployment..."
    
    # Check deployment directory exists
    if [[ ! -d "$FRONTEND_DEPLOY_DIR" ]]; then
        print_status "error" "Deployment directory not found: $FRONTEND_DEPLOY_DIR"
        return 1
    fi
    
    # Check index.html exists
    if [[ ! -f "$FRONTEND_DEPLOY_DIR/index.html" ]]; then
        print_status "error" "index.html not found in deployment"
        return 1
    fi
    
    # Check for assets directory
    if [[ ! -d "$FRONTEND_DEPLOY_DIR/assets" ]]; then
        print_status "warning" "Assets directory not found (may be using different build structure)"
    fi
    
    # Check for at least one JS or CSS file
    local has_js=false
    local has_css=false
    
    if find "$FRONTEND_DEPLOY_DIR" -name "*.js" -type f | grep -q .; then
        has_js=true
    fi
    
    if find "$FRONTEND_DEPLOY_DIR" -name "*.css" -type f | grep -q .; then
        has_css=true
    fi
    
    if [[ "$has_js" == false ]] && [[ "$has_css" == false ]]; then
        print_status "warning" "No JavaScript or CSS files found in deployment"
    fi
    
    # Check file permissions
    local bad_perms=false
    for file in $(find "$FRONTEND_DEPLOY_DIR" -type f -not -perm 644 2>/dev/null | head -5); do
        if [[ -n "$file" ]]; then
            print_status "warning" "File with incorrect permissions: $file"
            bad_perms=true
        fi
    done
    
    if [[ "$bad_perms" == true ]]; then
        print_status "warning" "Some files have incorrect permissions"
    fi
    
    # Check directory permissions
    local bad_dir_perms=false
    for dir in $(find "$FRONTEND_DEPLOY_DIR" -type d -not -perm 755 2>/dev/null | head -5); do
        if [[ -n "$dir" ]]; then
            print_status "warning" "Directory with incorrect permissions: $dir"
            bad_dir_perms=true
        fi
    done
    
    if [[ "$bad_dir_perms" == true ]]; then
        print_status "warning" "Some directories have incorrect permissions"
    fi
    
    print_status "success" "Frontend verification completed"
    
    # Return success if index.html exists
    return 0
}

# Main frontend setup function
setup_frontend() {
    print_status "step" "Setting up frontend application..."
    
    local backup_path=""
    local deploy_success=false
    
    # Backup existing deployment
    if [[ -d "$FRONTEND_DEPLOY_DIR" ]]; then
        if ! backup_frontend; then
            print_status "warning" "Failed to backup existing deployment, continuing..."
        fi
        backup_path=$(cat /tmp/codexpanel-frontend-backup-path 2>/dev/null || echo "")
    fi
    
    # Install dependencies
    if ! install_frontend_dependencies; then
        print_status "error" "Failed to install frontend dependencies"
        rollback_frontend
        return 1
    fi
    
    # Build frontend
    if ! build_frontend; then
        print_status "error" "Failed to build frontend"
        rollback_frontend
        return 1
    fi
    
    # Deploy frontend
    if ! deploy_frontend; then
        print_status "error" "Failed to deploy frontend"
        rollback_frontend
        return 1
    fi
    
    # Verify deployment
    if verify_frontend; then
        deploy_success=true
        print_status "success" "Frontend setup completed successfully"
    else
        print_status "error" "Frontend verification failed"
        rollback_frontend
        return 1
    fi
    
    # Clean up backup if deployment was successful
    if [[ "$deploy_success" == true ]] && [[ -n "$backup_path" ]] && [[ -d "$backup_path" ]]; then
        print_status "info" "Cleaning up backup: $backup_path"
        rm -rf "$backup_path" 2>/dev/null || true
        rm -f /tmp/codexpanel-frontend-backup-path 2>/dev/null || true
    fi
    
    return 0
}

# Export functions
export -f install_frontend_dependencies
export -f build_frontend
export -f deploy_frontend
export -f backup_frontend
export -f rollback_frontend
export -f verify_frontend
export -f setup_frontend

# Export variables
export FRONTEND_DIR
export FRONTEND_BUILD_DIR
export FRONTEND_DEPLOY_DIR
export FRONTEND_BACKUP_DIR
export FRONTEND_OWNER
export FRONTEND_GROUP