#!/bin/bash
# Codex Panel - Nginx Configuration Module
# This file handles Nginx installation and configuration

set -e

# Function to install Nginx
install_nginx() {
    print_status "step" "Installing Nginx..."
    
    # Check if Nginx is already installed
    if command_exists nginx; then
        local nginx_version=$(nginx -v 2>&1 | cut -d'/' -f2)
        print_status "info" "Nginx $nginx_version already installed"
        
        # Check if we need to upgrade
        print_status "info" "Checking for Nginx updates..."
        apt-get install --only-upgrade -y nginx >> "$LOG_FILE" 2>&1
        
        print_status "success" "Nginx is up to date"
        return 0
    fi
    
    # Install Nginx from official repositories
    print_status "info" "Installing Nginx from official repository..."
    
    # Add Nginx official repository for latest stable version
    if [[ ! -f /etc/apt/sources.list.d/nginx.list ]]; then
        echo "deb [arch=amd64] http://nginx.org/packages/ubuntu/ $(lsb_release -cs) nginx" > /etc/apt/sources.list.d/nginx.list
        echo "deb-src http://nginx.org/packages/ubuntu/ $(lsb_release -cs) nginx" >> /etc/apt/sources.list.d/nginx.list
        
        # Add Nginx signing key
        curl -fsSL https://nginx.org/keys/nginx_signing.key | gpg --dearmor -o /usr/share/keyrings/nginx-archive-keyring.gpg
        
        # Verify key fingerprint
        local key_fingerprint=$(gpg --dry-run --quiet --import --import-options import-show /usr/share/keyrings/nginx-archive-keyring.gpg 2>&1 | grep -oP '([A-F0-9]{4} ){9}[A-F0-9]{4}' | head -1)
        if [[ "$key_fingerprint" != "573B FD6B 3D8F BC64 1079 A6AB ABF5 BD82 7BD9 BF62" ]]; then
            print_status "error" "Nginx signing key verification failed"
            rollback "Nginx Installation"
        fi
        
        # Update package lists
        apt-get update -qq
    fi
    
    # Install Nginx
    DEBIAN_FRONTEND=noninteractive apt-get install -y nginx >> "$LOG_FILE" 2>&1
    
    if [[ $? -ne 0 ]]; then
        print_status "error" "Failed to install Nginx"
        rollback "Nginx Installation"
    fi
    
    # Verify installation
    if command_exists nginx; then
        local nginx_version=$(nginx -v 2>&1 | cut -d'/' -f2)
        print_status "success" "Nginx $nginx_version installed successfully"
    else
        print_status "error" "Nginx installation verification failed"
        rollback "Nginx Installation"
    fi
    
    # Create required directories
    create_nginx_directories
    
    # Configure Nginx
    configure_nginx_global
    
    # Start Nginx
    systemctl start nginx
    systemctl enable nginx
    
    wait_for_service "nginx" 30
    
    print_status "success" "Nginx installed and started"
}

# Function to create Nginx directories
create_nginx_directories() {
    print_status "step" "Creating Nginx directories..."
    
    local directories=(
        "/etc/nginx/sites-available"
        "/etc/nginx/sites-enabled"
        "/etc/nginx/conf.d"
        "/etc/nginx/ssl"
        "/var/log/nginx"
        "/var/www/codexpanel"
        "/var/www/codexpanel/html"
        "/var/www/codexpanel/logs"
    )
    
    for dir in "${directories[@]}"; do
        create_directory "$dir" "root:root" 755
    done
    
    # Create default index page
    cat > /var/www/codexpanel/html/index.html <<'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Codex Panel</title>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        body {
            font-family: Arial, sans-serif;
            text-align: center;
            padding: 50px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            margin: 0;
            min-height: 100vh;
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;
        }
        h1 {
            font-size: 48px;
            margin-bottom: 20px;
        }
        p {
            font-size: 18px;
            opacity: 0.9;
        }
        .logo {
            font-size: 64px;
            margin-bottom: 30px;
        }
    </style>
</head>
<body>
    <div class="logo">⚡</div>
    <h1>Codex Panel</h1>
    <p>Your modern web hosting control panel</p>
    <p style="font-size: 14px; margin-top: 30px; opacity: 0.7;">
        Installation in progress...
    </p>
</body>
</html>
EOF
    
    print_status "success" "Nginx directories created"
}

# Function to configure global Nginx settings
configure_nginx_global() {
    print_status "step" "Configuring global Nginx settings..."
    
    # Backup original configuration
    backup_file "/etc/nginx/nginx.conf"
    
    # Create optimized nginx.conf
    cat > /etc/nginx/nginx.conf <<'EOF'
user  nginx;
worker_processes  auto;
worker_rlimit_nofile 65535;

error_log  /var/log/nginx/error.log warn;
pid        /var/run/nginx.pid;

events {
    worker_connections  4096;
    use                 epoll;
    multi_accept        on;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    # Logging
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for" '
                    '"$host" $request_time $upstream_response_time';
    
    access_log /var/log/nginx/access.log main buffer=32k flush=5s;
    error_log /var/log/nginx/error.log warn;

    # Performance tuning
    sendfile            on;
    tcp_nopush          on;
    tcp_nodelay         on;
    keepalive_timeout   65;
    keepalive_requests  1000;
    types_hash_max_size 2048;
    server_tokens       off;

    # Buffer settings
    client_body_buffer_size 128k;
    client_max_body_size 100M;
    client_header_buffer_size 1k;
    large_client_header_buffers 4 8k;

    # Timeouts
    client_body_timeout 60;
    client_header_timeout 60;
    send_timeout 60;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript 
               application/json application/javascript application/xml+rss 
               application/rss+xml application/atom+xml 
               image/svg+xml text/x-js text/x-cross-domain-policy 
               application/x-font-ttf application/x-font-opentype 
               application/vnd.ms-fontobject application/font-woff 
               application/font-woff2;
    gzip_disable "msie6";
    gzip_min_length 1024;
    gzip_http_version 1.1;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Permissions-Policy "geolocation=(), microphone=(), camera=()" always;

    # SSL settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384';
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 1d;
    ssl_session_tickets off;
    ssl_stapling on;
    ssl_stapling_verify on;
    resolver 8.8.8.8 1.1.1.1 valid=300s;
    resolver_timeout 5s;

    # Include virtual host configurations
    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}
EOF
    
    # Validate configuration
    nginx -t >> "$LOG_FILE" 2>&1
    
    if [[ $? -ne 0 ]]; then
        print_status "error" "Invalid Nginx configuration"
        # Restore backup
        if [[ -f "/etc/nginx/nginx.conf.backup"* ]]; then
            local backup=$(ls -t /etc/nginx/nginx.conf.backup.* | head -1)
            cp "$backup" /etc/nginx/nginx.conf
            print_status "info" "Restored backup configuration"
        fi
        rollback "Nginx Global Configuration"
    fi
    
    print_status "success" "Global Nginx configuration applied"
}

# Function to configure Nginx site
configure_nginx() {
    print_status "step" "Configuring Nginx site for Codex Panel..."
    
    # Check if Nginx is installed
    if ! command_exists nginx; then
        print_status "error" "Nginx is not installed"
        rollback "Nginx Configuration"
    fi
    
    # Create site configuration
    create_site_config
    
    # Enable site
    enable_site
    
    # Configure security
    configure_security_headers
    
    print_status "success" "Nginx site configured"
}

# Function to create site configuration
create_site_config() {
    print_status "step" "Creating site configuration..."
    
    local site_config="$NGINX_SITES_AVAILABLE/$PANEL_DOMAIN"
    
    # Check if configuration already exists
    if [[ -f "$site_config" ]]; then
        print_status "warning" "Site configuration already exists"
        backup_file "$site_config"
    fi
    
    # Create site configuration
    cat > "$site_config" <<EOF
# Codex Panel - $PANEL_DOMAIN
# Generated: $(date)

# HTTP server block
server {
    listen 80;
    listen [::]:80;
    server_name $PANEL_DOMAIN;
    
    # Redirect to HTTPS
    return 301 https://\$server_name\$request_uri;
}

# HTTPS server block
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name $PANEL_DOMAIN;
    
    # Root directory
    root /var/www/codexpanel/html;
    index index.html index.htm;
    
    # SSL certificates (configured by certbot)
    ssl_certificate /etc/letsencrypt/live/$PANEL_DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$PANEL_DOMAIN/privkey.pem;
    
    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Permissions-Policy "geolocation=(), microphone=(), camera=()" always;
    
    # Logs
    access_log /var/www/codexpanel/logs/access.log main;
    error_log /var/www/codexpanel/logs/error.log warn;
    
    # Static files (frontend)
    location / {
        try_files \$uri \$uri/ /index.html;
        expires 1h;
        add_header Cache-Control "public, max-age=3600, immutable";
    }
    
    # Static assets (cache longer)
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot|otf)$ {
        expires 1y;
        add_header Cache-Control "public, max-age=31536000, immutable";
        try_files \$uri =404;
    }
    
    # API proxy to backend
    location /api {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        
        # Proxy timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        
        # Buffer settings
        proxy_buffering off;
        proxy_buffer_size 4k;
        proxy_buffers 8 4k;
        proxy_busy_buffers_size 8k;
        
        # Headers
        proxy_set_header X-Request-Id \$request_id;
    }
    
    # WebSocket support (if needed)
    location /socket.io {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    # Health check
    location /health {
        proxy_pass http://localhost:3000/health;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        access_log off;
    }
    
    # Deny access to hidden files
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    # Deny access to sensitive files
    location ~* \.(env|log|sql|sqlite|ini|conf|config|json|lock|md|txt|git|gitignore|htaccess|htpasswd)$ {
        deny all;
        access_log off;
        log_not_found off;
    }
}

# IPv6 fallback (if IPv6 is not available)
server {
    listen 80;
    server_name $PANEL_DOMAIN;
    
    # Redirect to HTTPS
    return 301 https://\$server_name\$request_uri;
}
EOF
    
    # Validate configuration
    nginx -t >> "$LOG_FILE" 2>&1
    
    if [[ $? -ne 0 ]]; then
        print_status "error" "Invalid site configuration"
        rm -f "$site_config"
        rollback "Site Configuration"
    fi
    
    print_status "success" "Site configuration created: $site_config"
}

# Function to enable site
enable_site() {
    print_status "step" "Enabling site..."
    
    local site_config="$NGINX_SITES_AVAILABLE/$PANEL_DOMAIN"
    local site_enabled="$NGINX_SITES_ENABLED/$PANEL_DOMAIN"
    
    # Check if configuration exists
    if [[ ! -f "$site_config" ]]; then
        print_status "error" "Site configuration not found: $site_config"
        rollback "Site Enable"
    fi
    
    # Remove existing symlink
    if [[ -L "$site_enabled" ]]; then
        rm -f "$site_enabled"
    fi
    
    # Create symlink
    ln -s "$site_config" "$site_enabled"
    
    # Test configuration
    nginx -t >> "$LOG_FILE" 2>&1
    
    if [[ $? -ne 0 ]]; then
        print_status "error" "Failed to enable site: invalid configuration"
        rm -f "$site_enabled"
        rollback "Site Enable"
    fi
    
    # Reload Nginx
    systemctl reload nginx
    
    print_status "success" "Site enabled: $PANEL_DOMAIN"
}

# Function to configure security headers
configure_security_headers() {
    print_status "step" "Configuring security headers..."
    
    # Create security headers file
    cat > /etc/nginx/conf.d/security-headers.conf <<'EOF'
# Security headers for Codex Panel
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
add_header Permissions-Policy "geolocation=(), microphone=(), camera=()" always;
add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; font-src 'self'; connect-src 'self' https:; frame-ancestors 'none'; form-action 'self'; base-uri 'self';" always;
EOF
    
    # Validate configuration
    nginx -t >> "$LOG_FILE" 2>&1
    
    if [[ $? -eq 0 ]]; then
        systemctl reload nginx
        print_status "success" "Security headers configured"
    else
        print_status "warning" "Failed to configure security headers"
        rm -f /etc/nginx/conf.d/security-headers.conf
    fi
}

# Function to configure SSL for Nginx
configure_nginx_ssl() {
    print_status "step" "Configuring SSL for Nginx..."
    
    # Create SSL directory
    create_directory "/etc/nginx/ssl" "root:root" 755
    
    # Generate self-signed certificate as fallback
    if [[ ! -f "/etc/nginx/ssl/$PANEL_DOMAIN.crt" ]]; then
        print_status "info" "Generating self-signed certificate..."
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout "/etc/nginx/ssl/$PANEL_DOMAIN.key" \
            -out "/etc/nginx/ssl/$PANEL_DOMAIN.crt" \
            -subj "/CN=$PANEL_DOMAIN" >> "$LOG_FILE" 2>&1
        
        chmod 600 "/etc/nginx/ssl/$PANEL_DOMAIN.key"
        chmod 644 "/etc/nginx/ssl/$PANEL_DOMAIN.crt"
    fi
    
    # Update site configuration to use SSL
    local site_config="$NGINX_SITES_AVAILABLE/$PANEL_DOMAIN"
    
    if [[ -f "$site_config" ]]; then
        # Update SSL certificate paths to use self-signed if Let's Encrypt not available
        sed -i "s|/etc/letsencrypt/live/$PANEL_DOMAIN/fullchain.pem|/etc/nginx/ssl/$PANEL_DOMAIN.crt|g" "$site_config"
        sed -i "s|/etc/letsencrypt/live/$PANEL_DOMAIN/privkey.pem|/etc/nginx/ssl/$PANEL_DOMAIN.key|g" "$site_config"
        
        # Validate configuration
        nginx -t >> "$LOG_FILE" 2>&1
        
        if [[ $? -eq 0 ]]; then
            systemctl reload nginx
            print_status "success" "SSL configured for Nginx"
        else
            print_status "error" "Failed to configure SSL"
            rollback "SSL Configuration"
        fi
    fi
}

# Function to update Nginx site after SSL
update_nginx_site() {
    local domain="$1"
    local ssl_cert="$2"
    local ssl_key="$3"
    
    print_status "step" "Updating Nginx site configuration..."
    
    local site_config="$NGINX_SITES_AVAILABLE/$domain"
    
    if [[ ! -f "$site_config" ]]; then
        print_status "error" "Site configuration not found: $site_config"
        return 1
    fi
    
    # Backup configuration
    backup_file "$site_config"
    
    # Update SSL certificate paths
    sed -i "s|ssl_certificate .*|ssl_certificate $ssl_cert;|g" "$site_config"
    sed -i "s|ssl_certificate_key .*|ssl_certificate_key $ssl_key;|g" "$site_config"
    
    # Enable HSTS
    sed -i "/add_header Strict-Transport-Security/d" "$site_config"
    sed -i "/add_header X-Frame-Options/a\    add_header Strict-Transport-Security \"max-age=31536000; includeSubDomains\" always;" "$site_config"
    
    # Validate configuration
    nginx -t >> "$LOG_FILE" 2>&1
    
    if [[ $? -eq 0 ]]; then
        systemctl reload nginx
        print_status "success" "Nginx site updated with SSL"
        return 0
    else
        print_status "error" "Failed to update Nginx site"
        # Restore backup
        if [[ -f "$site_config.backup"* ]]; then
            local backup=$(ls -t "$site_config.backup."* | head -1)
            cp "$backup" "$site_config"
            print_status "info" "Restored backup configuration"
        fi
        return 1
    fi
}

# Function to test Nginx configuration
test_nginx() {
    print_status "step" "Testing Nginx configuration..."
    
    nginx -t >> "$LOG_FILE" 2>&1
    
    if [[ $? -eq 0 ]]; then
        print_status "success" "Nginx configuration is valid"
        return 0
    else
        print_status "error" "Nginx configuration is invalid"
        return 1
    fi
}

# Function to reload Nginx
reload_nginx() {
    print_status "step" "Reloading Nginx..."
    
    if systemctl is-active --quiet nginx; then
        systemctl reload nginx
        
        if [[ $? -eq 0 ]]; then
            print_status "success" "Nginx reloaded successfully"
            return 0
        else
            print_status "error" "Failed to reload Nginx"
            return 1
        fi
    else
        print_status "error" "Nginx is not running"
        return 1
    fi
}

# Function to start Nginx
start_nginx() {
    print_status "step" "Starting Nginx..."
    
    if ! systemctl is-active --quiet nginx; then
        systemctl start nginx
        systemctl enable nginx
        
        wait_for_service "nginx" 30
        
        if systemctl is-active --quiet nginx; then
            print_status "success" "Nginx started successfully"
            return 0
        else
            print_status "error" "Failed to start Nginx"
            return 1
        fi
    else
        print_status "info" "Nginx is already running"
        return 0
    fi
}

# Function to stop Nginx
stop_nginx() {
    print_status "step" "Stopping Nginx..."
    
    if systemctl is-active --quiet nginx; then
        systemctl stop nginx
        
        if [[ $? -eq 0 ]]; then
            print_status "success" "Nginx stopped successfully"
            return 0
        else
            print_status "error" "Failed to stop Nginx"
            return 1
        fi
    else
        print_status "info" "Nginx is already stopped"
        return 0
    fi
}

# Function to disable site
disable_site() {
    local domain="$1"
    print_status "step" "Disabling site: $domain"
    
    local site_enabled="$NGINX_SITES_ENABLED/$domain"
    
    if [[ -L "$site_enabled" ]]; then
        rm -f "$site_enabled"
        
        # Test configuration
        nginx -t >> "$LOG_FILE" 2>&1
        
        if [[ $? -eq 0 ]]; then
            systemctl reload nginx
            print_status "success" "Site disabled: $domain"
            return 0
        else
            print_status "error" "Failed to disable site"
            return 1
        fi
    else
        print_status "info" "Site is not enabled: $domain"
        return 0
    fi
}

# Function to remove site
remove_site() {
    local domain="$1"
    print_status "step" "Removing site: $domain"
    
    # Disable site first
    disable_site "$domain"
    
    # Remove configuration
    local site_config="$NGINX_SITES_AVAILABLE/$domain"
    
    if [[ -f "$site_config" ]]; then
        rm -f "$site_config"
        print_status "success" "Site configuration removed: $domain"
    fi
    
    # Remove SSL certificates
    if [[ -d "/etc/letsencrypt/live/$domain" ]]; then
        rm -rf "/etc/letsencrypt/live/$domain"
        print_status "info" "SSL certificates removed: $domain"
    fi
    
    # Remove web root
    if [[ -d "/var/www/$domain" ]]; then
        rm -rf "/var/www/$domain"
        print_status "info" "Web root removed: /var/www/$domain"
    fi
}

# Export functions for use in other modules
export -f install_nginx
export -f configure_nginx
export -f create_nginx_directories
export -f configure_nginx_global
export -f create_site_config
export -f enable_site
export -f configure_security_headers
export -f configure_nginx_ssl
export -f update_nginx_site
export -f test_nginx
export -f reload_nginx
export -f start_nginx
export -f stop_nginx
export -f disable_site
export -f remove_site