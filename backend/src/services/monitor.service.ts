import os from "os";
import fs from "fs";
import { promisify } from "util";
import { exec } from "child_process";

const execAsync = promisify(exec);

function formatBytes(bytes: number) {
  return Math.round(bytes / 1024 / 1024);
}

export async function getServerStats() {
  const totalRam = os.totalmem();
  const freeRam = os.freemem();
  const usedRam = totalRam - freeRam;

  const cpus = os.cpus();

  const cpuModel = cpus[0]?.model || "Unknown";
  const cpuCores = cpus.length;

  let disk = {
    total: 0,
    used: 0,
    available: 0,
    usage: 0,
  };

  if (process.platform !== "win32") {
    try {
      const { stdout } = await execAsync("df -k /");

      const lines = stdout.trim().split("\n");

      if (lines.length > 1) {
        const parts = lines[1].trim().split(/\s+/);

        const total = Number(parts[1]) * 1024;
        const used = Number(parts[2]) * 1024;
        const available = Number(parts[3]) * 1024;
        const usage = parseInt(parts[4].replace("%", ""));

        disk = {
          total,
          used,
          available,
          usage,
        };
      }
    } catch {}
  }

  let nginx = false;
  let mysql = false;

  if (process.platform !== "win32") {
    try {
      await execAsync("systemctl is-active --quiet nginx");
      nginx = true;
    } catch {}

    try {
      await execAsync("systemctl is-active --quiet mysql");
      mysql = true;
    } catch {}
  }

  return {
    os: {
      platform: os.platform(),
      release: os.release(),
      hostname: os.hostname(),
      uptime: os.uptime(),
      architecture: os.arch(),
    },

    cpu: {
      model: cpuModel,
      cores: cpuCores,
      usage: os.loadavg()[0],
    },

    ram: {
      total: formatBytes(totalRam),
      used: formatBytes(usedRam),
      free: formatBytes(freeRam),
      usage: Math.round((usedRam / totalRam) * 100),
    },

    disk: {
      total: formatBytes(disk.total),
      used: formatBytes(disk.used),
      free: formatBytes(disk.available),
      usage: disk.usage,
    },

    services: {
      nginx,
      mysql,
    },

    node: process.version,
  };
}