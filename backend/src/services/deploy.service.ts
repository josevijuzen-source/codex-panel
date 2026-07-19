import fs from "fs/promises";
import path from "path";
import { exec } from "child_process";
import { promisify } from "util";

const execAsync = promisify(exec);

import { createNginxConfig } from "./nginx.service";

async function createWebsiteDirectory(domain: string) {
  const root = `/var/www/${domain}`;

  const folders = [
    "",
    "public",
    "logs",
    "backups",
    "ssl",
    "tmp",
    "uploads",
    "config",
  ];

  for (const folder of folders) {
    await fs.mkdir(path.join(root, folder), { recursive: true });
  }

  // Default index.html
  await fs.writeFile(
    path.join(root, "public", "index.html"),
    `<!DOCTYPE html>
<html>
<head>
<title>${domain}</title>
</head>
<body>
<h1>🎉 ${domain} is hosted successfully!</h1>
<p>Powered by Codex Panel</p>
</body>
</html>`
  );
}

export async function deployWebsite(website: { domain: string }) {
  console.log(`🚀 Deploying ${website.domain}...`);

  // Create website folders
  await createWebsiteDirectory(website.domain);

  // Skip nginx on Windows
  if (process.platform === "win32") {
    console.log("⚠ Windows detected. Nginx deployment skipped.");
    return;
  }

  // Create nginx config
  await createNginxConfig(website.domain);

  // Test nginx configuration
  await execAsync("nginx -t");

  // Reload nginx
  await execAsync("systemctl reload nginx");

  console.log(`✅ ${website.domain} deployed successfully`);
}