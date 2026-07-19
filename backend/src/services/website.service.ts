import { promisify } from "util";
import { exec } from "child_process";
import fs from "fs/promises";

const execAsync = promisify(exec);

export async function startWebsite(domain: string) {
  const available = `/etc/nginx/sites-available/${domain}`;
  const enabled = `/etc/nginx/sites-enabled/${domain}`;

  try {
    await fs.access(enabled);
  } catch {
    await execAsync(`ln -s ${available} ${enabled}`);
  }

  await execAsync("nginx -t");
  await execAsync("systemctl reload nginx");

  return {
    success: true,
    message: `${domain} started`,
  };
}

export async function stopWebsite(domain: string) {
  const enabled = `/etc/nginx/sites-enabled/${domain}`;

  try {
    await fs.unlink(enabled);
  } catch {}

  await execAsync("nginx -t");
  await execAsync("systemctl reload nginx");

  return {
    success: true,
    message: `${domain} stopped`,
  };
}

export async function restartWebsite(domain: string) {
  await execAsync("nginx -t");
  await execAsync("systemctl reload nginx");

  return {
    success: true,
    message: `${domain} restarted`,
  };
}