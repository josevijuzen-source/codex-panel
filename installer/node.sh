#!/bin/bash
# Codex Panel - Node.js Installation Module
# This file handles Node.js and npm installation

# Function to install Node.js
install_nodejs() {
    print_status "step" "Installing Node.js LTS..."
    
    # Check if Node.js is already installed
    if command_exists node; then
        local current_version=$(node --version)
        print_status "info" "Node.js $current_version already installed"
        
        # Check if version is >= 20
        local major_version=$(echo "$current_version" | cut -d'.' -f1 | tr -d 'v')
        if [[ $major_version -ge 20 ]]; then
            print_status "success" "Node.js version $current_version is sufficient"
            return 0
        else
            print_status "warning" "Node.js $current_version is outdated, upgrading..."
        fi
    fi
    
    # Install Node.js from official repository
    print_status "info" "Adding Node.js repository..."
    
    # Download and run Node.js setup script
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - >> "$LOG_FILE" 2>&1
    
    if [[ $? -ne 0 ]]; then
        print_status "error" "Failed to add Node.js repository"
        rollback "Node.js Installation"
    fi
    
    # Install Node.js
    print_status "info" "Installing Node.js..."
    apt-get install -y nodejs >> "$LOG_FILE" 2>&1
    
    if [[ $? -ne 0 ]]; then
        print_status "error" "Failed to install Node.js"
        rollback "Node.js Installation"
    fi
    
    # Install build tools for native modules
    print_status "info" "Installing build tools..."
    apt-get install -y build-essential >> "$LOG_FILE" 2>&1
    
    # Verify installation
    local node_version=$(node --version)
    local npm_version=$(npm --version)
    
    print_status "success" "Node.js $node_version installed successfully"
    print_status "success" "npm $npm_version installed successfully"
    
    # Configure npm
    print_status "info" "Configuring npm..."
    npm config set loglevel error
    npm config set progress false
    npm config set fund false
    npm config set audit false
    
    # Install global packages
    install_global_packages
}

# Function to install global npm packages
install_global_packages() {
    print_status "step" "Installing global npm packages..."
    
    local packages=(
        "pm2"
        "yarn"
        "nodemon"
        "typescript"
        "ts-node"
        "@nestjs/cli"
        "prisma"
        "rimraf"
        "cross-env"
        "concurrently"
        "forever"
        "serve"
        "http-server"
    )
    
    for package in "${packages[@]}"; do
        print_status "info" "Installing $package globally..."
        npm install -g "$package" >> "$LOG_FILE" 2>&1
        
        if [[ $? -eq 0 ]]; then
            print_status "success" "Package $package installed globally"
        else
            print_status "warning" "Failed to install package $package"
        fi
    done
    
    # Verify global installations
    if command_exists pm2; then
        print_status "success" "PM2 installed successfully"
    fi
}

# Function to setup PM2
setup_pm2() {
    print_status "step" "Setting up PM2..."
    
    # Create PM2 configuration directory
    mkdir -p /etc/pm2
    
    # Generate PM2 startup script
    pm2 startup systemd -u root --hp /root >> "$LOG_FILE" 2>&1
    
    # Save PM2 process list
    pm2 save >> "$LOG_FILE" 2>&1
    
    print_status "success" "PM2 setup completed"
}

# Function to check Node.js version
check_node_version() {
    if ! command_exists node; then
        return 1
    fi
    
    local current_version=$(node --version | tr -d 'v')
    local required_version="20.0.0"
    
    if [[ $(printf '%s\n' "$required_version" "$current_version" | sort -V | head -n1) == "$required_version" ]]; then
        return 0
    else
        return 1
    fi
}

# Function to configure Node.js environment
configure_node_env() {
    print_status "step" "Configuring Node.js environment..."
    
    # Create npm cache directory
    mkdir -p /root/.npm
    chmod 755 /root/.npm
    
    # Create global node_modules directory
    mkdir -p /usr/lib/node_modules
    chmod 755 /usr/lib/node_modules
    
    # Set npm configuration globally
    npm config set cache /root/.npm --global
    npm config set prefix /usr --global
    
    # Create environment variables file
    cat > /etc/profile.d/nodejs.sh <<'EOF'
export NODE_ENV=production
export NPM_CONFIG_LOGLEVEL=error
export NPM_CONFIG_PROGRESS=false
export NPM_CONFIG_FUND=false
export NPM_CONFIG_AUDIT=false
EOF
    
    chmod +x /etc/profile.d/nodejs.sh
    
    print_status "success" "Node.js environment configured"
}

# Function to clean npm cache
clean_npm_cache() {
    print_status "step" "Cleaning npm cache..."
    
    npm cache clean --force >> "$LOG_FILE" 2>&1
    
    print_status "success" "npm cache cleaned"
}

# Function to install yarn as alternative
install_yarn() {
    print_status "step" "Installing Yarn package manager..."
    
    if ! command_exists yarn; then
        # Add Yarn repository
        curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - >> "$LOG_FILE" 2>&1
        echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list >> "$LOG_FILE" 2>&1
        
        apt-get update -qq
        apt-get install -y yarn >> "$LOG_FILE" 2>&1
        
        print_status "success" "Yarn installed successfully"
    else
        print_status "info" "Yarn already installed"
    fi
}