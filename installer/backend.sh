#!/bin/bash
# Codex Panel - Backend Setup Module
# This file handles backend application setup

# Function to setup backend
setup_backend() {
    print_status "step" "Setting up backend application..."
    
    # Create backend directory structure
    create_backend_directories
    
    # Initialize backend application
    init_backend_app
    
    # Install backend dependencies
    install_backend_dependencies
    
    # Configure environment
    configure_backend_env
    
    # Setup database
    setup_backend_database
    
    # Build backend
    build_backend
    
    # Setup PM2
    setup_backend_pm2
    
    print_status "success" "Backend setup completed"
}

# Function to create backend directories
create_backend_directories() {
    print_status "step" "Creating backend directories..."
    
    create_directory "$BACKEND_DIR" "root:root" 755
    
    # Create subdirectories
    create_directory "$BACKEND_DIR/src" "root:root" 755
    create_directory "$BACKEND_DIR/src/controllers" "root:root" 755
    create_directory "$BACKEND_DIR/src/models" "root:root" 755
    create_directory "$BACKEND_DIR/src/routes" "root:root" 755
    create_directory "$BACKEND_DIR/src/middleware" "root:root" 755
    create_directory "$BACKEND_DIR/src/utils" "root:root" 755
    create_directory "$BACKEND_DIR/src/services" "root:root" 755
    create_directory "$BACKEND_DIR/prisma" "root:root" 755
    create_directory "$BACKEND_DIR/uploads" "www-data:www-data" 755
    create_directory "$BACKEND_DIR/logs" "www-data:www-data" 755
    
    print_status "success" "Backend directories created"
}

# Function to initialize backend application
init_backend_app() {
    print_status "step" "Initializing backend application..."
    
    cd "$BACKEND_DIR"
    
    # Initialize package.json
    cat > package.json <<'EOF'
{
  "name": "codex-panel-backend",
  "version": "1.0.0",
  "description": "Codex Panel Backend API",
  "main": "dist/index.js",
  "scripts": {
    "build": "tsc",
    "start": "node dist/index.js",
    "dev": "nodemon src/index.ts",
    "prisma:generate": "prisma generate",
    "prisma:push": "prisma db push",
    "prisma:studio": "prisma studio",
    "test": "jest",
    "lint": "eslint . --ext .ts",
    "format": "prettier --write ."
  },
  "keywords": [
    "codex-panel",
    "backend",
    "api"
  ],
  "author": "Codex Panel Team",
  "license": "MIT",
  "dependencies": {
    "@prisma/client": "^5.0.0",
    "bcrypt": "^5.1.0",
    "cors": "^2.8.5",
    "dotenv": "^16.0.3",
    "express": "^4.18.2",
    "express-rate-limit": "^6.7.0",
    "helmet": "^7.0.0",
    "ioredis": "^5.3.2",
    "jsonwebtoken": "^9.0.0",
    "multer": "^1.4.5-lts.1",
    "mysql2": "^3.5.1",
    "uuid": "^9.0.0",
    "winston": "^3.9.0"
  },
  "devDependencies": {
    "@types/bcrypt": "^5.0.0",
    "@types/cors": "^2.8.13",
    "@types/express": "^4.17.17",
    "@types/jsonwebtoken": "^9.0.2",
    "@types/multer": "^1.4.7",
    "@types/node": "^20.0.0",
    "@types/uuid": "^9.0.2",
    "@typescript-eslint/eslint-plugin": "^5.59.0",
    "@typescript-eslint/parser": "^5.59.0",
    "eslint": "^8.39.0",
    "jest": "^29.5.0",
    "nodemon": "^2.0.22",
    "prettier": "^2.8.8",
    "prisma": "^5.0.0",
    "ts-node": "^10.9.1",
    "typescript": "^5.0.4"
  },
  "prisma": {
    "schema": "prisma/schema.prisma"
  }
}
EOF
    
    # Create TypeScript configuration
    cat > tsconfig.json <<'EOF'
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "commonjs",
    "lib": ["ES2020"],
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "moduleResolution": "node",
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true,
    "experimentalDecorators": true,
    "emitDecoratorMetadata": true,
    "noImplicitAny": true,
    "strictNullChecks": true,
    "strictFunctionTypes": true,
    "strictPropertyInitialization": true,
    "noImplicitThis": true,
    "alwaysStrict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist", "**/*.test.ts"]
}
EOF
    
    # Create Prisma schema
    cat > prisma/schema.prisma <<'EOF'
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "mysql"
  url      = env("DATABASE_URL")
}

model User {
  id        String    @id @default(uuid())
  username  String    @unique
  email     String    @unique
  password  String
  firstName String?
  lastName  String?
  role      String    @default("user")
  status    String    @default("active")
  createdAt DateTime  @default(now())
  updatedAt DateTime  @updatedAt
  lastLogin DateTime?
  
  sessions  Session[]
  logs      AuditLog[]
}

model Session {
  id        String   @id @default(uuid())
  userId    String
  token     String   @unique
  userAgent String?
  ipAddress String?
  expiresAt DateTime
  createdAt DateTime @default(now())
  
  user      User     @relation(fields: [userId], references: [id])
}

model AuditLog {
  id        String   @id @default(uuid())
  userId    String
  action    String
  details   Json?
  ipAddress String?
  userAgent String?
  createdAt DateTime @default(now())
  
  user      User     @relation(fields: [userId], references: [id])
}

model Setting {
  key       String   @id
  value     Json
  group     String   @default("general")
  description String?
  updatedAt DateTime @updatedAt
}

model Domain {
  id        String   @id @default(uuid())
  name      String   @unique
  status    String   @default("active")
  sslEnabled Boolean @default(false)
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
}
EOF
    
    # Create main application file
    cat > src/index.ts <<'EOF'
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import dotenv from 'dotenv';
import { createServer } from 'http';
import { PrismaClient } from '@prisma/client';
import logger from './utils/logger';
import router from './routes';
import { errorHandler } from './middleware/errorHandler';
import { rateLimiter } from './middleware/rateLimiter';

dotenv.config();

const app = express();
const prisma = new PrismaClient();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(helmet());
app.use(cors({
  origin: process.env.CORS_ORIGIN || '*',
  credentials: true
}));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(rateLimiter);

// Static files
app.use('/uploads', express.static('uploads'));

// Routes
app.use('/api', router);

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Error handling
app.use(errorHandler);

// Start server
const server = createServer(app);

server.listen(PORT, () => {
  logger.info(`Server running on port ${PORT}`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  logger.info('SIGTERM signal received: closing HTTP server');
  server.close(() => {
    logger.info('HTTP server closed');
    prisma.$disconnect();
    process.exit(0);
  });
});

export default app;
EOF
    
    print_status "success" "Backend application initialized"
}

# Function to install backend dependencies
install_backend_dependencies() {
    print_status "step" "Installing backend dependencies..."
    
    cd "$BACKEND_DIR"
    
    # Install dependencies
    npm install --production=false >> "$LOG_FILE" 2>&1
    
    if [[ $? -ne 0 ]]; then
        print_status "error" "Failed to install backend dependencies"
        rollback "Backend Dependencies Installation"
    fi
    
    print_status "success" "Backend dependencies installed"
}

# Function to configure backend environment
configure_backend_env() {
    print_status "step" "Configuring backend environment..."
    
    cd "$BACKEND_DIR"
    
    # Create .env file
    cat > .env <<EOF
# Application
NODE_ENV=production
PORT=3000
APP_NAME=Codex Panel

# Database
DATABASE_URL="mysql://${DB_USER}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}"

# Redis
REDIS_HOST=${REDIS_HOST}
REDIS_PORT=${REDIS_PORT}

# JWT
JWT_SECRET=$(openssl rand -base64 32)
JWT_EXPIRES_IN=7d

# Admin User
ADMIN_USERNAME=${ADMIN_USERNAME}
ADMIN_PASSWORD=${ADMIN_PASSWORD}
ADMIN_EMAIL=${ADMIN_EMAIL}

# CORS
CORS_ORIGIN=https://${PANEL_DOMAIN}

# Logging
LOG_LEVEL=info
LOG_FILE=/var/log/codexpanel/backend.log

# Upload
UPLOAD_DIR=./uploads
MAX_FILE_SIZE=10485760

# Session
SESSION_SECRET=$(openssl rand -base64 32)
SESSION_EXPIRY=86400

# Email
SMTP_HOST=localhost
SMTP_PORT=25
SMTP_SECURE=false
SMTP_USER=
SMTP_PASS=
EOF
    
    chmod 600 .env
    
    print_status "success" "Backend environment configured"
}

# Function to setup backend database
setup_backend_database() {
    print_status "step" "Setting up backend database..."
    
    cd "$BACKEND_DIR"
    
    # Generate Prisma client
    print_status "info" "Generating Prisma client..."
    npx prisma generate >> "$LOG_FILE" 2>&1
    
    if [[ $? -ne 0 ]]; then
        print_status "error" "Failed to generate Prisma client"
        rollback "Backend Database Setup"
    fi
    
    # Push database schema
    print_status "info" "Pushing database schema..."
    npx prisma db push >> "$LOG_FILE" 2>&1
    
    if [[ $? -ne 0 ]]; then
        print_status "error" "Failed to push database schema"
        rollback "Backend Database Setup"
    fi
    
    # Create admin user
    print_status "info" "Creating admin user..."
    create_admin_user
    
    print_status "success" "Backend database setup completed"
}

# Function to create admin user
create_admin_user() {
    cd "$BACKEND_DIR"
    
    # Create seed script
    cat > prisma/seed.ts <<'EOF'
import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcrypt';
import dotenv from 'dotenv';

dotenv.config();

const prisma = new PrismaClient();

async function main() {
  const adminUsername = process.env.ADMIN_USERNAME || 'admin';
  const adminPassword = process.env.ADMIN_PASSWORD || 'admin123';
  const adminEmail = process.env.ADMIN_EMAIL || 'admin@localhost';
  
  // Hash password
  const hashedPassword = await bcrypt.hash(adminPassword, 10);
  
  // Create admin user
  const admin = await prisma.user.upsert({
    where: { username: adminUsername },
    update: {},
    create: {
      username: adminUsername,
      email: adminEmail,
      password: hashedPassword,
      role: 'admin',
      status: 'active'
    }
  });
  
  console.log(`Admin user created: ${admin.username}`);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
EOF
    
    # Run seed script
    npx ts-node prisma/seed.ts >> "$LOG_FILE" 2>&1
    
    print_status "success" "Admin user created"
}

# Function to build backend
build_backend() {
    print_status "step" "Building backend..."
    
    cd "$BACKEND_DIR"
    
    # Run build
    npm run build >> "$LOG_FILE" 2>&1
    
    if [[ $? -ne 0 ]]; then
        print_status "error" "Failed to build backend"
        rollback "Backend Build"
    fi
    
    print_status "success" "Backend built successfully"
}

# Function to setup backend with PM2
setup_backend_pm2() {
    print_status "step" "Setting up backend with PM2..."
    
    cd "$BACKEND_DIR"
    
    # Create PM2 ecosystem file
    cat > ecosystem.config.js <<'EOF'
module.exports = {
  apps: [{
    name: 'codexpanel-backend',
    script: 'dist/index.js',
    instances: '1',
    exec_mode: 'fork',
    env: {
      NODE_ENV: 'production'
    },
    error_file: '/var/log/codexpanel/backend-error.log',
    out_file: '/var/log/codexpanel/backend-out.log',
    log_file: '/var/log/codexpanel/backend-combined.log',
    time: true,
    watch: false,
    autorestart: true,
    max_memory_restart: '1G',
    min_uptime: '10s',
    max_restarts: 10
  }]
};
EOF
    
    # Start application with PM2
    pm2 start ecosystem.config.js >> "$LOG_FILE" 2>&1
    
    if [[ $? -ne 0 ]]; then
        print_status "error" "Failed to start backend with PM2"
        rollback "PM2 Backend Setup"
    fi
    
    # Save PM2 configuration
    pm2 save >> "$LOG_FILE" 2>&1
    
    print_status "success" "Backend running with PM2"
}