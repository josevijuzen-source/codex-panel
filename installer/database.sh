#!/bin/bash
# Codex Panel - Database Installation Module
# This file handles MariaDB and Redis installation

# Function to install MariaDB
install_mariadb() {
    print_status "step" "Installing MariaDB..."
    
    # Add MariaDB repository
    if [[ "$OS_ID" == "ubuntu" ]]; then
        print_status "info" "Adding MariaDB repository..."
        apt-key adv --fetch-keys 'https://mariadb.org/mariadb_release_signing_key.asc' >> "$LOG_FILE" 2>&1
        add-apt-repository "deb [arch=amd64,arm64,ppc64el] https://mirror.mariadb.org/repo/10.11/ubuntu $OS_VERSION main" >> "$LOG_FILE" 2>&1
        apt-get update -qq
    fi
    
    # Install MariaDB
    print_status "info" "Installing MariaDB server..."
    DEBIAN_FRONTEND=noninteractive apt-get install -y mariadb-server mariadb-client >> "$LOG_FILE" 2>&1
    
    if [[ $? -ne 0 ]]; then
        print_status "error" "Failed to install MariaDB"
        rollback "MariaDB Installation"
    fi
    
    # Start and enable MariaDB
    systemctl start mariadb
    systemctl enable mariadb
    
    # Wait for MariaDB to start
    wait_for_service "mariadb" 60
    
    print_status "success" "MariaDB installed successfully"
    
    # Secure MariaDB installation
    secure_mariadb
    
    # Create database and user
    create_database
}

# Function to secure MariaDB
secure_mariadb() {
    print_status "step" "Securing MariaDB installation..."
    
    # Generate random root password
    local MYSQL_ROOT_PASSWORD=$(generate_password 24)
    
    # Secure MariaDB installation
    mysql <<EOF
-- Set root password
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
-- Remove anonymous users
DELETE FROM mysql.user WHERE User='';
-- Disallow remote root login
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
-- Remove test database
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
-- Flush privileges
FLUSH PRIVILEGES;
EOF
    
    # Save root password
    echo "MariaDB Root Password: $MYSQL_ROOT_PASSWORD" >> "$LOG_FILE"
    echo "$MYSQL_ROOT_PASSWORD" > /root/.mariadb_root_password
    chmod 600 /root/.mariadb_root_password
    
    print_status "success" "MariaDB secured successfully"
    print_status "info" "MariaDB root password saved to /root/.mariadb_root_password"
}

# Function to create database and user
create_database() {
    print_status "step" "Creating database and user..."
    
    # Generate random password
    DB_PASSWORD=$(generate_password 24)
    
    # Create database and user
    mysql <<EOF
CREATE DATABASE IF NOT EXISTS ${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';
FLUSH PRIVILEGES;
EOF
    
    if [[ $? -eq 0 ]]; then
        print_status "success" "Database and user created successfully"
        print_status "info" "Database: $DB_NAME, User: $DB_USER"
        print_status "info" "Database password saved to /root/.codexpanel_db_password"
        
        # Save database credentials
        cat > /root/.codexpanel_db_password <<EOF
Database: $DB_NAME
User: $DB_USER
Password: $DB_PASSWORD
Host: $DB_HOST
Port: $DB_PORT
EOF
        chmod 600 /root/.codexpanel_db_password
    else
        print_status "error" "Failed to create database and user"
        rollback "Database Creation"
    fi
}

# Function to install Redis
install_redis() {
    print_status "step" "Installing Redis..."
    
    # Install Redis
    if [[ "$OS_ID" == "ubuntu" ]] || [[ "$OS_ID" == "debian" ]]; then
        apt-get install -y redis-server redis-tools >> "$LOG_FILE" 2>&1
    else
        print_status "error" "Unsupported OS for Redis installation"
        rollback "Redis Installation"
    fi
    
    if [[ $? -ne 0 ]]; then
        print_status "error" "Failed to install Redis"
        rollback "Redis Installation"
    fi
    
    # Configure Redis
    print_status "info" "Configuring Redis..."
    
    # Backup original configuration
    backup_file "/etc/redis/redis.conf"
    
    # Update Redis configuration
    cat > /etc/redis/redis.conf <<EOF
# Redis configuration for Codex Panel
port 6379
bind 127.0.0.1
protected-mode yes
daemonize yes
pidfile /var/run/redis/redis-server.pid
logfile /var/log/redis/redis-server.log
databases 16
maxmemory 256mb
maxmemory-policy allkeys-lru
save 900 1
save 300 10
save 60 10000
EOF
    
    # Start and enable Redis
    systemctl restart redis
    systemctl enable redis
    
    wait_for_service "redis" 30
    
    print_status "success" "Redis installed and configured successfully"
}

# Function to test database connection
test_database_connection() {
    print_status "step" "Testing database connection..."
    
    if mysql -u "$DB_USER" -p"$DB_PASSWORD" -h "$DB_HOST" -P "$DB_PORT" -e "SELECT 1" > /dev/null 2>&1; then
        print_status "success" "Database connection successful"
        return 0
    else
        print_status "error" "Database connection failed"
        return 1
    fi
}

# Function to backup database
backup_database() {
    print_status "step" "Backing up database..."
    
    local backup_dir="/var/backups/codexpanel"
    mkdir -p "$backup_dir"
    local backup_file="$backup_dir/db_backup_$(date +%Y%m%d_%H%M%S).sql.gz"
    
    mysqldump -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" | gzip > "$backup_file"
    
    if [[ $? -eq 0 ]]; then
        print_status "success" "Database backed up to $backup_file"
        return 0
    else
        print_status "error" "Database backup failed"
        return 1
    fi
}

# Function to restore database
restore_database() {
    local backup_file="$1"
    
    if [[ ! -f "$backup_file" ]]; then
        print_status "error" "Backup file not found: $backup_file"
        return 1
    fi
    
    print_status "step" "Restoring database from $backup_file..."
    
    gunzip -c "$backup_file" | mysql -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME"
    
    if [[ $? -eq 0 ]]; then
        print_status "success" "Database restored successfully"
        return 0
    else
        print_status "error" "Database restore failed"
        return 1
    fi
}