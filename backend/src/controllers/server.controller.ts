import { Request, Response } from "express";
import si from "systeminformation";

export const getServerStats = async (
  req: Request,
  res: Response
) => {
  try {
    const [load, mem, disks, os, time] = await Promise.all([
      si.currentLoad(),
      si.mem(),
      si.fsSize(),
      si.osInfo(),
      si.time(),
    ]);

    res.json({
      cpu: load.currentLoad,
      ramUsed: mem.active,
      ramTotal: mem.total,
      diskUsed: disks[0]?.used ?? 0,
      diskTotal: disks[0]?.size ?? 0,
      os: {
        distro: os.distro,
        release: os.release,
        platform: os.platform,
      },
      uptime: {
        uptime: time.uptime,
      },
    });
  } catch (error) {
    console.error(error);

    res.status(500).json({
      success: false,
      message: "Failed to get server stats",
    });
  }
};