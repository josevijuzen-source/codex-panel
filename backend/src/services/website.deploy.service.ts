import fs from "fs/promises";
import path from "path";
import { promisify } from "util";
import { exec } from "child_process";

import prisma from "../lib/prisma";
import { createNginxConfig } from "./nginx.service";

const execAsync = promisify(exec);

class WebsiteDeployService {
  private validateDomain(domain: string): boolean {
    const regex =
      /^(?!-)[A-Za-z0-9-]{1,63}(?<!-)\.[A-Za-z]{2,}$/;

    return regex.test(domain);
  }

  async deploy(domain: string, ownerId: number) {
    try {
      if (!this.validateDomain(domain)) {
        throw new Error("Invalid domain name.");
      }

      const exists = await prisma.website.findUnique({
        where: {
          domain,
        },
      });

      if (exists) {
        throw new Error("Website already exists.");
      }

      const websiteRoot =
        process.platform === "win32"
          ? path.join(process.cwd(), "websites", domain)
          : `/var/www/${domain}`;

      const publicDir = path.join(websiteRoot, "public");
      const logsDir = path.join(websiteRoot, "logs");

      await fs.mkdir(publicDir, {
        recursive: true,
      });

      await fs.mkdir(logsDir, {
        recursive: true,
      });

      await fs.writeFile(
        path.join(publicDir, "index.html"),
        `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>${domain}</title>
<style>
body{
margin:0;
display:flex;
justify-content:center;
align-items:center;
height:100vh;
background:#0f172a;
font-family:Arial,sans-serif;
color:#fff;
}
.box{
text-align:center;
padding:40px;
background:#1e293b;
border-radius:15px;
box-shadow:0 0 25px rgba(0,0,0,.3);
}
h1{
margin-bottom:10px;
}
p{
color:#cbd5e1;
}
</style>
</head>
<body>
<div class="box">
<h1>🚀 ${domain}</h1>
<p>Website deployed successfully.</p>
</div>
</body>
</html>`
      );

      if (process.platform !== "win32") {
        await createNginxConfig(domain);

        try {
          await execAsync(`chown -R www-data:www-data "${websiteRoot}"`);
        } catch {}

        try {
          await execAsync(`chmod -R 755 "${websiteRoot}"`);
        } catch {}
      }

      const website = await prisma.website.create({
  data: {
    name: domain,

    domain,

    runtime: "Node.js",

    version: "22",

    rootPath: websiteRoot,

    nginxConfig:
      process.platform === "win32"
        ? null
        : `/etc/nginx/sites-available/${domain}`,

    cpu: 1,

    ram: 1024,

    disk: 10240,

    ssl: false,

    forceHttps: false,

    status: "Running",

    ownerId,
  },
});
      return {
        success: true,
        message: "Website deployed successfully.",
        website,
      };
    } catch (error: any) {
      return {
        success: false,
        message: error?.message ?? "Unknown error",
      };
    }
  }

  async remove(domain: string) {
    try {
      const website = await prisma.website.findUnique({
        where: {
          domain,
        },
      });

      if (!website) {
        throw new Error("Website not found.");
      }

      await fs.rm(website.rootPath, {
        recursive: true,
        force: true,
      });

      if (process.platform !== "win32") {
        try {
          await execAsync(
            `rm -f /etc/nginx/sites-enabled/${domain}`
          );
          await execAsync(
            `rm -f /etc/nginx/sites-available/${domain}`
          );
          await execAsync("nginx -t");
          await execAsync("systemctl reload nginx");
        } catch {}
      }

      await prisma.website.delete({
        where: {
          domain,
        },
      });

      return {
        success: true,
        message: "Website deleted successfully.",
      };
    } catch (error: any) {
      return {
        success: false,
        message: error?.message ?? "Unknown error",
      };
    }
  }
}

export default new WebsiteDeployService();