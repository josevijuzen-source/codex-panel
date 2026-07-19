import { Router } from "express";
import { BackupController } from "../controllers/backup.controller";

const router = Router();

// Get all backups
router.get("/", BackupController.getAll);

// Create backup
router.post("/create", BackupController.create);

// Download backup
router.get("/download/:id", BackupController.download);

// Delete backup
router.delete("/:id", BackupController.delete);

export default router;