import { Request, Response } from "express";
import path from "path";

export const downloadFile = (
  req: Request,
  res: Response
) => {
  try {
    const filePath = req.query.path as string;

    if (!filePath) {
      return res.status(400).json({
        success: false,
        message: "File path required",
      });
    }

    return res.download(path.resolve(filePath));
  } catch (error) {
    console.error(error);

    return res.status(500).json({
      success: false,
      message: "Download failed",
    });
  }
};