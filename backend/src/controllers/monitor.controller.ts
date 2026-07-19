import { Request, Response } from "express";
import { getServerStats } from "../services/monitor.service";

export const getMonitor = async (
  req: Request,
  res: Response
) => {
  try {
    const stats = await getServerStats();

    return res.json({
      success: true,
      stats,
    });
  } catch (error) {
    console.error(error);

    return res.status(500).json({
      success: false,
      message: "Failed to fetch server statistics",
    });
  }
};