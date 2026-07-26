#!/bin/bash
# Codex Panel - Package Installation Module
# This file handles the installation of system packages

# Function to install required system packages
install_required_packages() {
    print_status "step" "Installing required packages..."
    
    # List of required packages
    local packages=(
        # Build tools
        build-essential
        gcc
        g++
        make
        cmake
        autoconf
        automake
        libtool
        
        # Development libraries
        libssl-dev
        libreadline-dev
        zlib1g-dev
        libbz2-dev
        libsqlite3-dev
        libffi-dev
        liblzma-dev
        libpq-dev
        libxml2-dev
        libxslt1-dev
        libyaml-dev
        
        # Network tools
        curl
        wget
        net-tools
        dnsutils
        iputils-ping
        telnet
        nmap
        
        # System utilities
        git
        subversion
        unzip
        zip
        gzip
        tar
        rsync
        htop
        tree
        jq
        vim
        nano
        
        # Database clients
        mysql-client
        postgresql-client
        
        # Security tools
        fail2ban
        ufw
        iptables
        
        # Monitoring
        sysstat
        netdata
        monit
        
        # Additional utilities
        software-properties-common
        apt-transport-https
        ca-certificates
        gnupg
        lsb-release
        python3
        python3-pip
        python3-venv
        
        # Service management
        systemd
        cron
        logrotate
    )
    
    # Install packages
    local failed_packages=()
    
    for package in "${packages[@]}"; do
        if package_installed "$package"; then
            print_status "info" "Package $package already installed"
            continue
        fi
        
        print_status "info" "Installing $package..."
        
        DEBIAN_FRONTEND=noninteractive apt-get install -y "$package" >> "$LOG_FILE" 2>&1
        
        if [[ $? -eq 0 ]]; then
            print_status "success" "Package $package installed successfully"
        else
            print_status "warning" "Failed to install package $package"
            failed_packages+=("$package")
        fi
    done
    
    # Report on failed packages
    if [[ ${#failed_packages[@]} -gt 0 ]]; then
        print_status "warning" "The following packages failed to install:"
        for package in "${failed_packages[@]}"; do
            echo -e "  ${YELLOW}✗${NC} $package"
        done
        print_status "warning" "Continuing with installation, but some features may not work"
    else
        print_status "success" "All required packages installed successfully"
    fi
}

# Function to install additional tools
install_additional_tools() {
    print_status "step" "Installing additional tools..."
    
    # Install Composer (PHP dependency manager)
    if ! command_exists composer; then
        print_status "info" "Installing Composer..."
        curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
        chmod +x /usr/local/bin/composer
        print_status "success" "Composer installed successfully"
    fi
    
    # Install Python package manager
    if command_exists pip3; then
        print_status "info" "Upgrading pip..."
        pip3 install --upgrade pip >> "$LOG_FILE" 2>&1
        
        print_status "info" "Installing Python packages..."
        pip3 install \
            requests \
            click \
            colorama \
            python-dotenv \
            pyyaml \
            jinja2 \
            boto3 \
            awscli \
            >> "$LOG_FILE" 2>&1
        print_status "success" "Python packages installed"
    fi
    
    # Install Docker if not available (optional)
    if ! command_exists docker; then
        print_status "info" "Docker not installed, skipping..."
    fi
    
    # Install kubectl if not available (optional)
    if ! command_exists kubectl; then
        print_status "info" "kubectl not installed, skipping..."
    fi
}

# Function to configure firewall
configure_firewall() {
    print_status "step" "Configuring firewall..."
    
    if command_exists ufw; then
        # Default policies
        ufw default deny incoming
        ufw default allow outgoing
        
        # Allow SSH
        ufw allow 22/tcp
        
        # Allow HTTP/HTTPS
        ufw allow 80/tcp
        ufw allow 443/tcp
        
        # Allow application ports
        if [[ -n "$APP_PORT" ]]; then
            ufw allow "$APP_PORT"/tcp
        fi
        
        # Enable firewall
        echo "y" | ufw enable 2>/dev/null
        
        print_status "success" "Firewall configured with UFW"
    else
        print_status "warning" "UFW not available, skipping firewall configuration"
    fi
}

# Function to configure fail2ban
configure_fail2ban() {
    print_status "step" "Configuring fail2ban..."
    
    if command_exists fail2ban-client; then
        # Create local configuration
        cat > /etc/fail2ban/jail.local <<'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log

[nginx-http-auth]
enabled = true
port = http,https
filter = nginx-http-auth
logpath = /var/log/nginx/error.log
EOF
        
        # Restart fail2ban
        systemctl restart fail2ban
        systemctl enable fail2ban
        
        print_status "success" "Fail2ban configured successfully"
    else
        print_status "warning" "Fail2ban not installed, skipping configuration"
    fi
}

# Function to setup log rotation
setup_log_rotation() {
    print_status "step" "Setting up log rotation..."
    
    # Create logrotate configuration
    cat > /etc/logrotate.d/codexpanel <<'EOF'
/var/log/codexpanel/*.log {
    daily
    rotate 14
    compress
    delaycompress
    missingok
    notifempty
    create 640 root root
    postrotate
        systemctl reload codexpanel > /dev/null 2>&1 || true
    endscript
}
EOF
    
    print_status "success" "Log rotation configured"
}

# Function to setup cron jobs
setup_cron_jobs() {
    print_status "step" "Setting up cron jobs..."
    
    # Create a cron file for Codex Panel
    cat > /etc/cron.d/codexpanel <<'EOF'
# Codex Panel Maintenance
0 2 * * * root /opt/codex-panel/scripts/maintenance.sh > /dev/null 2>&1
0 3 * * 0 root /opt/codex-panel/scripts/backup.sh > /dev/null 2>&1
*/5 * * * * root /opt/codex-panel/scripts/health-check.sh > /dev/null 2>&1
EOF
    
    # Create script directory
    mkdir -p /opt/codex-panel/scripts
    
    # Create maintenance script
    cat > /opt/codex-panel/scripts/maintenance.sh <<'EOF'
#!/bin/bash
# Codex Panel Maintenance Script
echo "Running maintenance tasks..."
# Clean logs
find /var/log/codexpanel -name "*.log" -mtime +30 -delete
# Clear cache
rm -rf /tmp/codexpanel-cache/*
# Check services
systemctl status codexpanel || systemctl restart codexpanel
EOF
    chmod +x /opt/codex-panel/scripts/maintenance.sh
    
    # Create backup script
    cat > /opt/codex-panel/scripts/backup.sh <<'EOF'
#!/bin/bash
# Codex Panel Backup Script
BACKUP_DIR="/var/backups/codexpanel"
mkdir -p "$BACKUP_DIR"
tar -czf "$BACKUP_DIR/backup-$(date +%Y%m%d).tar.gz" /opt/codex-panel 2>/dev/null
find "$BACKUP_DIR" -name "*.tar.gz" -mtime +30 -delete
EOF
    chmod +x /opt/codex-panel/scripts/backup.sh
    
    # Create health check script
    cat > /opt/codex-panel/scripts/health-check.sh <<'EOF'
#!/bin/bash
# Codex Panel Health Check Script
if ! curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/health | grep -q "200"; then
    echo "Health check failed, restarting service..."
    systemctl restart codexpanel
fi
EOF
    chmod +x /opt/codex-panel/scripts/health-check.sh
    
    print_status "success" "Cron jobs configured"
}