import { Request, Response } from "express";
import prisma from "../lib/prisma";

import { deleteItem } from "../services/delete.service";
import {
  listFiles,
  createFolder,
} from "../services/files.service";

import fs from "fs/promises";
import path from "path";

/* RENAME FILE */
export const renameFile = async (
  req: Request,
  res: Response
) => {
  try {
    const { path: directory, oldName, newName } = req.body;

    const oldPath = path.join(process.cwd(), directory, oldName);
    const newPath = path.join(process.cwd(), directory, newName);

    await fs.rename(oldPath, newPath);

    return res.json({
      success: true,
      message: "Renamed successfully",
    });
  } catch (error) {
    console.error(error);

    return res.status(500).json({
      success: false,
      message: "Rename failed",
    });
  }
};

/* DELETE FILE */
export const deleteFile = async (
  req: Request,
  res: Response
) => {
  try {
    const { path: currentPath, name } = req.body;

    await deleteItem(currentPath || ".", name);

    return res.json({
      success: true,
      message: "Deleted successfully",
    });
  } catch (error) {
    console.error(error);

    return res.status(500).json({
      success: false,
      message: "Delete failed",
    });
  }
};

/* GET FILES */
export const getFiles = async (
  req: Request,
  res: Response
) => {
  try {
    const websiteId = Number(req.query.websiteId);

    let directory = process.cwd();

    if (websiteId) {
      const website = await prisma.website.findUnique({
        where: {
          id: websiteId,
        },
      });

      if (website) {
        directory = website.rootPath;
      }
    }

    const files = await listFiles(directory);

    return res.json({
      success: true,
      files,
    });
  } catch (error) {
    console.error(error);

    return res.status(500).json({
      success: false,
      message: "Failed to load files",
    });
  }
};

/* CREATE FOLDER */
export const createFolderController = async (
  req: Request,
  res: Response
) => {
  try {
    const { directory, folderName } = req.body;

    await createFolder(directory, folderName);

    return res.json({
      success: true,
      message: "Folder created successfully",
    });
  } catch (error) {
    console.error(error);

    return res.status(500).json({
      success: false,
      message: "Failed to create folder",
    });
  }
};