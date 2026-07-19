import fs from "fs/promises";
import path from "path";
import { promisify } from "util";
import { exec } from "child_process";
import prisma from "../lib/prisma";

const execAsync = promisify(exec);

class WordPressService {
  async install(websiteId: number) {
    const website = await prisma.website.findUnique({
      where: {
        id: websiteId,
      },
    });

    if (!website) {
      throw new Error("Website not found.");
    }

    const publicPath = path.join(website.rootPath, "public");

    await fs.mkdir(publicPath, {
      recursive: true,
    });

    if (process.platform === "win32") {
      return {
        success: true,
        message:
          "Windows detected. WordPress download skipped.",
      };
    }

    await execAsync(
      `wget https://wordpress.org/latest.tar.gz -O /tmp/latest.tar.gz`
    );

    await execAsync(
      `tar -xzf /tmp/latest.tar.gz -C /tmp`
    );

    await execAsync(
      `cp -r /tmp/wordpress/* "${publicPath}"`
    );

    await execAsync(
      `rm -rf /tmp/wordpress /tmp/latest.tar.gz`
    );

    return {
      success: true,
      message: "WordPress files installed successfully.",
      path: publicPath,
    };
  }

  async remove(websiteId: number) {
    const website = await prisma.website.findUnique({
      where: {
        id: websiteId,
      },
    });

    if (!website) {
      throw new Error("Website not found.");
    }

    const publicPath = path.join(
      website.rootPath,
      "public"
    );

    await fs.rm(publicPath, {
      recursive: true,
      force: true,
    });

    await fs.mkdir(publicPath);

    return {
      success: true,
      message: "WordPress removed successfully.",
    };
  }
}

export default new WordPressService();