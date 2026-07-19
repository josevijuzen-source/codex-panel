import fs from "fs/promises";
import { promisify } from "util";
import { exec } from "child_process";

const execAsync = promisify(exec);

export async function createNginxConfig(domain: string) {
  // Skip nginx on Windows
  if (process.platform === "win32") {
    console.log("⚠ Windows detected. Skipping Nginx configuration.");
    return;
  }

  const config = `
server {
    listen 80;
    listen [::]:80;

    server_name ${domain} www.${domain};

    root /var/www/${domain}/public;
    index index.html index.htm index.php;

    access_log /var/www/${domain}/logs/access.log;
    error_log /var/www/${domain}/logs/error.log;

    client_max_body_size 512M;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location ~ \\.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.4-fpm.sock;
    }

    location ~ /\\.ht {
        deny all;
    }

    location = /favicon.ico {
        log_not_found off;
        access_log off;
    }

    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-Content-Type-Options "nosniff";
    add_header Referrer-Policy "strict-origin-when-cross-origin";

    gzip on;
    gzip_types text/plain text/css application/json application/javascript application/xml image/svg+xml;
}
`;

  const available = `/etc/nginx/sites-available/${domain}`;
  const enabled = `/etc/nginx/sites-enabled/${domain}`;

  await fs.writeFile(available, config);

  try {
    await fs.access(enabled);
  } catch {
    await execAsync(`ln -sf ${available} ${enabled}`);
  }

  await execAsync("nginx -t");
  await execAsync("systemctl reload nginx");

  console.log(`✅ Nginx configured for ${domain}`);

  return available;
}