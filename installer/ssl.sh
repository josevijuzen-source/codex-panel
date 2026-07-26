#!/bin/bash
# Codex Panel - SSL Certificate Management Module
# This file handles Let's Encrypt SSL certificate installation and management

set -e

# SSL configuration
SSL_BASE_DIR="/etc/letsencrypt"
SSL_LIVE_DIR="$SSL_BASE_DIR/live"
SSL_ARCHIVE_DIR="$SSL_BASE_DIR/archive"
SSL_RENEWAL_DIR="$SSL_BASE_DIR/renewal"
SSL_SELF_SIGNED_DIR="/etc/nginx/ssl"

# Self-signed certificate configuration
SELF_SIGNED_COUNTRY="${SELF_SIGNED_COUNTRY:-US}"
SELF_SIGNED_STATE="${SELF_SIGNED_STATE:-State}"
SELF_SIGNED_CITY="${SELF_SIGNED_CITY:-City}"
SELF_SIGNED_ORG="${SELF_SIGNED_ORG:-CodexPanel}"
SELF_SIGNED_DAYS="${SELF_SIGNED_DAYS:-365}"

# DNS verification configuration
DNS_TIMEOUT="${DNS_TIMEOUT:-5}"
DNS_RETRIES="${DNS_RETRIES:-2}"

# Temporary file cleanup trap
SSL_TEMP_FILES=()
cleanup_temp_files() {
    for temp_file in "${SSL_TEMP_FILES[@]}"; do
        if [[ -f "$temp_file" ]]; then
            rm -f "$temp_file"
        fi
    done
}
trap cleanup_temp_files EXIT

# Reusable OpenSSL helper functions
_openssl_check_cert() {
    local cert_path="$1"
    openssl x509 -in "$cert_path" -noout 2>/dev/null
}

_openssl_get_cert_info() {
    local cert_path="$1"
    local field="$2"
    openssl x509 -in "$cert_path" -"$field" -noout 2>/dev/null | cut -d'=' -f2-
}

_openssl_get_expiry() {
    local cert_path="$1"
    openssl x509 -in "$cert_path" -enddate -noout 2>/dev/null | cut -d'=' -f2
}

_openssl_check_valid() {
    local cert_path="$1"
    local days="${2:-86400}"
    openssl x509 -in "$cert_path" -checkend "$days" > /dev/null 2>&1
}

# Function to get server IPs using local system first
get_server_ips() {
    local ipv4=""
    local ipv6=""
    
    # Try local system detection first
    ipv4=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '^127\.' | head -1)
    
    # Fallback to external services if local detection fails
    if [[ -z "$ipv4" ]]; then
        ipv4=$(curl -s -4 --connect-timeout 5 ifconfig.me 2>/dev/null || 
               curl -s -4 --connect-timeout 5 icanhazip.com 2>/dev/null || echo "")
    fi
    
    # Get IPv6
    ipv6=$(ip -6 addr show scope global 2>/dev/null | grep inet6 | awk '{print $2}' | cut -d'/' -f1 | head -1)
    
    echo "$ipv4|$ipv6"
}

# Function to install Certbot
install_certbot() {
    print_status "step" "Installing Certbot..."
    
    if command_exists certbot; then
        local certbot_version
        certbot_version=$(certbot --version 2>&1 | cut -d' ' -f2)
        print_status "info" "Certbot $certbot_version already installed"
        
        apt-get install --only-upgrade -y certbot python3-certbot-nginx >> "$LOG_FILE" 2>&1
        print_status "success" "Certbot updated"
        return 0
    fi
    
    print_status "info" "Installing Certbot from Ubuntu repository..."
    apt-get update -qq
    
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        certbot \
        python3-certbot-nginx \
        >> "$LOG_FILE" 2>&1
    
    if [[ $? -ne 0 ]]; then
        print_status "error" "Failed to install Certbot"
        return 1
    fi
    
    if command_exists certbot; then
        local certbot_version
        certbot_version=$(certbot --version 2>&1 | cut -d' ' -f2)
        print_status "success" "Certbot $certbot_version installed successfully"
        return 0
    else
        print_status "error" "Certbot installation verification failed"
        return 1
    fi
}

# Function to validate domain format
validate_domain() {
    local domain="$1"
    
    if [[ -z "$domain" ]]; then
        print_status "error" "Domain is empty"
        return 1
    fi
    
    if [[ ! "$domain" =~ ^([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$ ]]; then
        print_status "error" "Invalid domain format: $domain"
        return 1
    fi
    
    if [[ "$domain" == "localhost" ]] || [[ "$domain" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        print_status "error" "Domain cannot be localhost or IP address: $domain"
        return 1
    fi
    
    print_status "success" "Domain validation passed: $domain"
    return 0
}

# Function to ensure dig is installed
ensure_dig_installed() {
    if ! command_exists dig; then
        print_status "info" "Installing dnsutils for DNS verification..."
        apt-get install -y dnsutils >> "$LOG_FILE" 2>&1
        if [[ $? -ne 0 ]]; then
            print_status "warning" "Failed to install dnsutils, DNS verification may be limited"
            return 1
        fi
        print_status "success" "dnsutils installed"
    fi
    return 0
}

# Function to verify DNS resolution
verify_domain_dns() {
    local domain="$1"
    local server_ips
    local server_ipv4
    local server_ipv6
    local resolved_ips
    local matched=false
    
    print_status "step" "Verifying DNS resolution for $domain..."
    
    ensure_dig_installed
    
    # Get server IPs
    IFS='|' read -r server_ipv4 server_ipv6 <<< "$(get_server_ips)"
    
    # Get resolved IPs with timeout
    resolved_ips=$(dig +timeout="$DNS_TIMEOUT" +retry="$DNS_RETRIES" +short "$domain" 2>/dev/null | 
                   grep -E '([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+|[a-fA-F0-9:]+)' || true)
    
    if [[ -z "$resolved_ips" ]]; then
        print_status "warning" "Could not resolve IP address for $domain"
        return 1
    fi
    
    # Check if domain resolves to this server
    local matched_ips=()
    while IFS= read -r ip; do
        if [[ -n "$ip" ]]; then
            if [[ "$ip" == "$server_ipv4" ]]; then
                matched=true
                matched_ips+=("$ip (IPv4)")
            elif [[ -n "$server_ipv6" ]] && [[ "$ip" == "$server_ipv6" ]]; then
                matched=true
                matched_ips+=("$ip (IPv6)")
            fi
        fi
    done <<< "$resolved_ips"
    
    if [[ "$matched" == true ]]; then
        print_status "success" "Domain $domain resolves to this server"
        for match in "${matched_ips[@]}"; do
            print_status "info" "  Matched: $match"
        done
        return 0
    else
        print_status "warning" "Domain $domain does not resolve to this server"
        [[ -n "$server_ipv4" ]] && print_status "info" "Server IPv4: $server_ipv4"
        [[ -n "$server_ipv6" ]] && print_status "info" "Server IPv6: $server_ipv6"
        print_status "info" "Resolved IPs: $resolved_ips"
        return 1
    fi
}

# Function to check if ports are available
check_ports_available() {
    print_status "step" "Checking if ports 80 and 443 are available..."
    
    local unavailable=()
    
    if port_in_use 80; then
        unavailable+=("80")
    fi
    
    if port_in_use 443; then
        unavailable+=("443")
    fi
    
    if [[ ${#unavailable[@]} -gt 0 ]]; then
        print_status "warning" "Ports ${unavailable[*]} are already in use"
        return 1
    else
        print_status "success" "Ports 80 and 443 are available"
        return 0
    fi
}

# Function to check existing certificate
check_existing_certificate() {
    local domain="$1"
    local cert_path="$SSL_LIVE_DIR/$domain/fullchain.pem"
    local key_path="$SSL_LIVE_DIR/$domain/privkey.pem"
    
    if [[ ! -f "$cert_path" ]] || [[ ! -f "$key_path" ]]; then
        return 1
    fi
    
    if _openssl_check_valid "$cert_path"; then
        local expiry_date
        expiry_date=$(_openssl_get_expiry "$cert_path")
        print_status "success" "Valid certificate exists for $domain (expires: $expiry_date)"
        return 0
    else
        print_status "warning" "Existing certificate has expired or will expire soon"
        return 1
    fi
}

# Function to request SSL certificate
request_certificate() {
    local domain="$1"
    local email="$2"
    local webroot="$3"
    local certbot_cmd=()
    local temp_log
    
    print_status "step" "Requesting SSL certificate for $domain..."
    
    if ! validate_domain "$domain"; then
        print_status "error" "Invalid domain: $domain"
        return 1
    fi
    
    if check_existing_certificate "$domain"; then
        print_status "info" "Valid certificate already exists"
        return 0
    fi
    
    # Verify DNS before proceeding
    if ! verify_domain_dns "$domain"; then
        print_status "warning" "DNS verification failed, generating self-signed certificate"
        generate_self_signed "$domain"
        return 1
    fi
    
    check_ports_available || print_status "warning" "Ports check failed, attempting with webroot method"
    
    # Build Certbot command array
    certbot_cmd=("certbot" "certonly")
    
    if [[ -n "$webroot" ]] && [[ -d "$webroot" ]]; then
        certbot_cmd+=("--webroot" "-w" "$webroot")
        print_status "info" "Using webroot method"
    elif command_exists nginx && systemctl is-active --quiet nginx 2>/dev/null; then
        certbot_cmd+=("--nginx")
        print_status "info" "Using Nginx plugin"
    else
        certbot_cmd+=("--standalone" "--preferred-challenges" "http")
        print_status "info" "Using standalone mode"
    fi
    
    certbot_cmd+=("-d" "$domain")
    
    if [[ -n "$email" ]]; then
        certbot_cmd+=("--email" "$email")
    else
        certbot_cmd+=("--register-unsafely-without-email")
    fi
    
    certbot_cmd+=("--agree-tos" "--non-interactive")
    
    print_status "info" "Running Certbot..."
    
    # Create temporary log file and track it
    temp_log=$(mktemp)
    SSL_TEMP_FILES+=("$temp_log")
    
    # Execute Certbot command using array
    if "${certbot_cmd[@]}" >> "$temp_log" 2>&1; then
        cat "$temp_log" >> "$LOG_FILE"
        print_status "success" "SSL certificate obtained successfully"
        return 0
    else
        local exit_code=$?
        cat "$temp_log" >> "$LOG_FILE"
        
        print_status "error" "Failed to obtain SSL certificate (exit code: $exit_code)"
        
        # Log failure details
        if [[ -f /var/log/letsencrypt/letsencrypt.log ]]; then
            tail -20 /var/log/letsencrypt/letsencrypt.log >> "$LOG_FILE"
        fi
        
        print_status "info" "Generating self-signed certificate as fallback..."
        generate_self_signed "$domain"
        return $exit_code
    fi
}

# Function to generate self-signed certificate
generate_self_signed() {
    local domain="$1"
    local cert_dir="$SSL_SELF_SIGNED_DIR"
    local cert_path="$cert_dir/$domain.crt"
    local key_path="$cert_dir/$domain.key"
    local openssl_cmd=()
    
    print_status "step" "Generating self-signed certificate for $domain..."
    
    create_directory "$cert_dir" "root:root" 755
    
    openssl_cmd=(
        "openssl" "req" "-x509" "-nodes" "-days" "$SELF_SIGNED_DAYS"
        "-newkey" "rsa:2048"
        "-keyout" "$key_path"
        "-out" "$cert_path"
        "-subj" "/C=$SELF_SIGNED_COUNTRY/ST=$SELF_SIGNED_STATE/L=$SELF_SIGNED_CITY/O=$SELF_SIGNED_ORG/CN=$domain"
    )
    
    if "${openssl_cmd[@]}" >> "$LOG_FILE" 2>&1; then
        chmod 600 "$key_path"
        chmod 644 "$cert_path"
        
        SSL_CERT_PATH="$cert_path"
        SSL_KEY_PATH="$key_path"
        export SSL_CERT_PATH SSL_KEY_PATH
        
        print_status "success" "Self-signed certificate generated"
        print_status "info" "Certificate: $cert_path"
        print_status "info" "Private key: $key_path"
        return 0
    else
        print_status "error" "Failed to generate self-signed certificate"
        return 1
    fi
}

# Function to verify certificate
verify_certificate() {
    local domain="$1"
    local cert_path="${2:-$SSL_LIVE_DIR/$domain/fullchain.pem}"
    
    print_status "step" "Verifying SSL certificate..."
    
    if [[ ! -f "$cert_path" ]]; then
        print_status "error" "Certificate file not found: $cert_path"
        return 1
    fi
    
    if ! _openssl_check_cert "$cert_path"; then
        print_status "error" "Invalid certificate file"
        return 1
    fi
    
    # Get certificate information using helper functions
    local subject issuer expiry_date days_remaining
    subject=$(_openssl_get_cert_info "$cert_path" "subject")
    issuer=$(_openssl_get_cert_info "$cert_path" "issuer")
    expiry_date=$(_openssl_get_expiry "$cert_path")
    
    local expiry_epoch current_epoch
    expiry_epoch=$(date -d "$expiry_date" +%s 2>/dev/null || echo 0)
    current_epoch=$(date +%s)
    
    if [[ $expiry_epoch -gt 0 ]]; then
        days_remaining=$(( (expiry_epoch - current_epoch) / 86400 ))
    else
        days_remaining="unknown"
    fi
    
    local is_letsencrypt=false
    echo "$issuer" | grep -q "Let's Encrypt" && is_letsencrypt=true
    
    print_status "success" "Certificate verification passed"
    print_status "info" "  Subject: $subject"
    print_status "info" "  Issuer: $issuer"
    print_status "info" "  Expires: $expiry_date"
    
    [[ "$days_remaining" != "unknown" ]] && print_status "info" "  Days remaining: $days_remaining"
    
    if [[ "$is_letsencrypt" == true ]]; then
        print_status "info" "  Type: Let's Encrypt (trusted)"
    else
        print_status "warning" "  Type: Self-signed (not trusted by browsers)"
    fi
    
    return 0
}

# Function to create renewal hook if it doesn't exist
create_renewal_hook() {
    local hook_path="$1"
    local hook_content="$2"
    
    if [[ -f "$hook_path" ]]; then
        print_status "info" "Renewal hook already exists: $hook_path"
        return 0
    fi
    
    mkdir -p "$(dirname "$hook_path")"
    echo "$hook_content" > "$hook_path"
    chmod +x "$hook_path"
    print_status "success" "Created renewal hook: $hook_path"
}

# Function to configure auto-renewal
configure_auto_renew() {
    print_status "step" "Configuring automatic certificate renewal..."
    
    local hook_dir="/etc/letsencrypt/renewal-hooks"
    local deploy_hook="$hook_dir/deploy/nginx-reload.sh"
    local pre_hook="$hook_dir/pre/stop-services.sh"
    local post_hook="$hook_dir/post/start-services.sh"
    
    # Create renewal hooks
    create_renewal_hook "$deploy_hook" '#!/bin/bash
echo "Certificate renewed, reloading Nginx..."
systemctl reload nginx 2>/dev/null || true
exit 0'
    
    create_renewal_hook "$pre_hook" '#!/bin/bash
# Stop services that might interfere with renewal
systemctl stop nginx 2>/dev/null || true
systemctl stop codexpanel 2>/dev/null || true
exit 0'
    
    create_renewal_hook "$post_hook" '#!/bin/bash
# Start services after renewal
systemctl start nginx 2>/dev/null || true
systemctl start codexpanel 2>/dev/null || true
exit 0'
    
    # Configure renewal timer or cron
    if systemctl list-unit-files 2>/dev/null | grep -q certbot.timer; then
        systemctl enable certbot.timer >> "$LOG_FILE" 2>&1
        systemctl start certbot.timer >> "$LOG_FILE" 2>&1
        print_status "success" "Certbot systemd timer enabled"
    elif [[ ! -f /etc/cron.d/certbot-renewal ]]; then
        cat > /etc/cron.d/certbot-renewal <<'EOF'
0 0,12 * * * root /usr/bin/certbot renew --quiet --post-hook "systemctl reload nginx" >> /var/log/certbot-renew.log 2>&1
EOF
        print_status "success" "Certbot cron job created"
    else
        print_status "info" "Certbot renewal already configured"
    fi
    
    # Test renewal
    print_status "info" "Testing renewal..."
    if certbot renew --dry-run >> "$LOG_FILE" 2>&1; then
        print_status "success" "Renewal test passed"
    else
        print_status "warning" "Renewal test failed, will retry automatically"
    fi
}

# Function to renew certificate
renew_certificate() {
    local domain="$1"
    local certbot_cmd=()
    
    print_status "step" "Renewing certificate for $domain..."
    
    if ! command_exists certbot; then
        print_status "error" "Certbot is not installed"
        return 1
    fi
    
    certbot_cmd=("certbot" "renew" "--cert-name" "$domain" "--quiet")
    
    if "${certbot_cmd[@]}" >> "$LOG_FILE" 2>&1; then
        print_status "success" "Certificate renewed successfully"
        if systemctl is-active --quiet nginx 2>/dev/null; then
            systemctl reload nginx
        fi
        return 0
    else
        local exit_code=$?
        print_status "error" "Certificate renewal failed (exit code: $exit_code)"
        return $exit_code
    fi
}

# Function to cleanup SSL
cleanup_ssl() {
    local domain="$1"
    local backup_dir
    local certbot_cmd=()
    
    print_status "step" "Cleaning up SSL for $domain..."
    
    # Backup existing certificate
    if [[ -d "$SSL_LIVE_DIR/$domain" ]]; then
        backup_dir="/tmp/ssl-backup-$domain-$(date +%Y%m%d_%H%M%S)"
        cp -r "$SSL_LIVE_DIR/$domain" "$backup_dir" 2>/dev/null || true
        print_status "info" "Certificate backed up to: $backup_dir"
    fi
    
    # Delete Let's Encrypt certificate
    if certbot certificates --cert-name "$domain" > /dev/null 2>&1; then
        certbot_cmd=("certbot" "delete" "--cert-name" "$domain" "--non-interactive")
        if "${certbot_cmd[@]}" >> "$LOG_FILE" 2>&1; then
            print_status "success" "Certificate deleted using certbot"
        else
            print_status "warning" "Certbot delete failed, performing manual cleanup"
            rm -rf "$SSL_LIVE_DIR/$domain" 2>/dev/null || true
            rm -rf "$SSL_ARCHIVE_DIR/$domain" 2>/dev/null || true
            rm -f "$SSL_RENEWAL_DIR/$domain.conf" 2>/dev/null || true
        fi
    fi
    
    # Remove self-signed certificates
    rm -f "$SSL_SELF_SIGNED_DIR/$domain.crt" "$SSL_SELF_SIGNED_DIR/$domain.key" 2>/dev/null || true
    
    print_status "success" "SSL cleanup completed"
    return 0
}

# Function to get certificate paths
get_certificate_paths() {
    local domain="$1"
    local cert_path=""
    local key_path=""
    
    # Check Let's Encrypt certificate
    if [[ -f "$SSL_LIVE_DIR/$domain/fullchain.pem" ]] && [[ -f "$SSL_LIVE_DIR/$domain/privkey.pem" ]]; then
        cert_path="$SSL_LIVE_DIR/$domain/fullchain.pem"
        key_path="$SSL_LIVE_DIR/$domain/privkey.pem"
    # Check self-signed certificate
    elif [[ -f "$SSL_SELF_SIGNED_DIR/$domain.crt" ]] && [[ -f "$SSL_SELF_SIGNED_DIR/$domain.key" ]]; then
        cert_path="$SSL_SELF_SIGNED_DIR/$domain.crt"
        key_path="$SSL_SELF_SIGNED_DIR/$domain.key"
    else
        return 1
    fi
    
    echo "$cert_path|$key_path"
    return 0
}

# Function to rollback SSL
rollback_ssl() {
    local domain="$1"
    local backup_dir="$2"
    
    print_status "step" "Rolling back SSL configuration..."
    
    if [[ -n "$backup_dir" ]] && [[ -d "$backup_dir" ]]; then
        # Restore from backup
        rm -rf "$SSL_LIVE_DIR/$domain" 2>/dev/null || true
        cp -r "$backup_dir" "$SSL_LIVE_DIR/$domain" 2>/dev/null || true
        print_status "success" "SSL configuration restored from backup"
        return 0
    else
        print_status "warning" "No backup found, generating self-signed certificate"
        generate_self_signed "$domain"
        return 1
    fi
}

# Function to setup SSL (main entry point)
setup_ssl() {
    local domain="$1"
    local email="${2:-$ADMIN_EMAIL}"
    local webroot="${3:-/var/www/codexpanel/html}"
    local backup_dir=""
    local ssl_status=0
    
    print_status "step" "Setting up SSL for Codex Panel..."
    
    # Backup existing certificate if it exists
    if [[ -d "$SSL_LIVE_DIR/$domain" ]]; then
        backup_dir="/tmp/ssl-backup-$domain-$(date +%Y%m%d_%H%M%S)"
        cp -r "$SSL_LIVE_DIR/$domain" "$backup_dir" 2>/dev/null || true
    fi
    
    # Install Certbot
    if ! install_certbot; then
        print_status "warning" "Certbot installation failed, generating self-signed certificate"
        generate_self_signed "$domain"
        ssl_status=1
    fi
    
    # Request certificate
    if [[ $ssl_status -eq 0 ]] && ! request_certificate "$domain" "$email" "$webroot"; then
        print_status "error" "Certificate request failed"
        ssl_status=1
    fi
    
    # Verify certificate
    if [[ $ssl_status -eq 0 ]]; then
        if verify_certificate "$domain"; then
            configure_auto_renew
            
            # Get certificate paths
            local cert_paths
            if cert_paths=$(get_certificate_paths "$domain"); then
                SSL_CERT_PATH=$(echo "$cert_paths" | cut -d'|' -f1)
                SSL_KEY_PATH=$(echo "$cert_paths" | cut -d'|' -f2)
                export SSL_CERT_PATH SSL_KEY_PATH
                print_status "success" "SSL setup completed successfully"
                return 0
            else
                print_status "error" "Failed to get certificate paths"
                ssl_status=1
            fi
        else
            print_status "error" "Certificate verification failed"
            ssl_status=1
        fi
    fi
    
    # Rollback on failure
    if [[ $ssl_status -ne 0 ]]; then
        print_status "error" "SSL setup failed, rolling back..."
        rollback_ssl "$domain" "$backup_dir"
        return 1
    fi
    
    return 0
}

# Export functions with comments
# install_certbot - Installs or updates Certbot and Nginx plugin
export -f install_certbot
# validate_domain - Validates domain name format
export -f validate_domain
# verify_domain_dns - Verifies DNS resolves to this server
export -f verify_domain_dns
# check_ports_available - Checks if ports 80 and 443 are available
export -f check_ports_available
# check_existing_certificate - Checks for valid existing certificate
export -f check_existing_certificate
# request_certificate - Requests SSL certificate from Let's Encrypt
export -f request_certificate
# generate_self_signed - Generates self-signed certificate as fallback
export -f generate_self_signed
# verify_certificate - Verifies certificate validity and details
export -f verify_certificate
# configure_auto_renew - Configures automatic certificate renewal
export -f configure_auto_renew
# renew_certificate - Manually renews a certificate
export -f renew_certificate
# cleanup_ssl - Cleans up SSL certificates for a domain
export -f cleanup_ssl
# get_certificate_paths - Returns certificate and key paths
export -f get_certificate_paths
# rollback_ssl - Rolls back SSL configuration on failure
export -f rollback_ssl
# setup_ssl - Main entry point for SSL setup
export -f setup_ssl

# Export variables
export SSL_BASE_DIR
export SSL_LIVE_DIR
export SSL_ARCHIVE_DIR
export SSL_RENEWAL_DIR
export SSL_SELF_SIGNED_DIR
export SSL_CERT_PATH=""
export SSL_KEY_PATH=""
export SELF_SIGNED_COUNTRY SELF_SIGNED_STATE SELF_SIGNED_CITY
export SELF_SIGNED_ORG SELF_SIGNED_DAYS
export DNS_TIMEOUT DNS_RETRIES