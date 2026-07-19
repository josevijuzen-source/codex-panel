import { Request, Response } from "express";
import si from "systeminformation";

class SystemController {
  async getStats(req: Request, res: Response) {
    try {
      const [
        cpu,
        mem,
        fs,
        os,
        currentLoad,
        network,
        time,
      ] = await Promise.all([
        si.cpu(),
        si.mem(),
        si.fsSize(),
        si.osInfo(),
        si.currentLoad(),
        si.networkStats(),
        si.time(),
      ]);

      const disk = fs.length > 0 ? fs[0] : null;
      const net = network.length > 0 ? network[0] : null;

      return res.json({
        success: true,
        data: {
          cpu: {
            manufacturer: cpu.manufacturer,
            brand: cpu.brand,
            cores: cpu.cores,
            physicalCores: cpu.physicalCores,
            speed: cpu.speed,
            usage: Number(currentLoad.currentLoad.toFixed(2)),
          },

          memory: {
            total: mem.total,
            used: mem.used,
            free: mem.free,
            usage: Number(((mem.used / mem.total) * 100).toFixed(2)),
          },

          disk: disk
            ? {
                total: disk.size,
                used: disk.used,
                available: disk.available,
                usage: Number(disk.use.toFixed(2)),
              }
            : null,

          network: net
            ? {
                rx: net.rx_bytes,
                tx: net.tx_bytes,
              }
            : null,

          system: {
            hostname: os.hostname,
            platform: os.platform,
            distro: os.distro,
            release: os.release,
            kernel: os.kernel,
            uptime: time.uptime,
          },
        },
      });
    } catch (error) {
      console.error(error);

      return res.status(500).json({
        success: false,
        message: "Failed to fetch system statistics.",
      });
    }
  }
}

export default new SystemController();