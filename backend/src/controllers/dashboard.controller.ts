import { Request, Response } from "express";
import { getDashboardStats } from "../services/dashboard.service";

export const getDashboard = async (
  req: Request,
  res: Response
) => {
  try {
    const stats = await getDashboardStats();

    return res.json({
      success: true,
      stats,
    });
  } catch (error) {
    console.error(error);

    return res.status(500).json({
      success: false,
      message: "Failed to load dashboard",
    });
  }
};