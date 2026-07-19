import { Request, Response } from "express";
import { renameItem } from "../services/rename.service";

export const renameFile = async (
  req: Request,
  res: Response
) => {
  try {
    const {
      path,
      oldName,
      newName,
    } = req.body;

    await renameItem(
      path || ".",
      oldName,
      newName
    );

    res.json({
      success: true,
      message: "Renamed successfully",
    });
  } catch (error) {
    console.error(error);

    res.status(500).json({
      success: false,
      message: "Rename failed",
    });
  }
};