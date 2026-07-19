import { Router } from "express";
import {
  getFiles,
  createFolderController,
  deleteFile,
  renameFile,
} from "../controllers/files.controller";

const router = Router();

/* List files */
router.get("/", getFiles);

/* Create folder */
router.post("/folder", createFolderController);

/* Delete file/folder */
router.delete("/", deleteFile);

/* Rename file/folder */
router.post("/rename", renameFile);

export default router;