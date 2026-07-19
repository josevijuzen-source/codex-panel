import { Request, Response } from "express";
import { BackupService } from "../services/backup.service";

export class BackupController {
    static getAll(req: Request, res: Response) {
        try {
            const backups = BackupService.getBackups();

            res.json({
                success: true,
                backups,
            });
        } catch (error) {
            res.status(500).json({
                success: false,
                message: "Failed to load backups.",
            });
        }
    }

    static create(req: Request, res: Response) {
        try {
            const result = BackupService.createBackup();

            res.json({
                success: true,
                message: "Backup created successfully.",
                data: result,
            });
        } catch (error) {
            res.status(500).json({
                success: false,
                message: "Failed to create backup.",
            });
        }
    }

    static download(req: Request, res: Response) {
        try {
            const id = String(req.params.id);

            const filePath = BackupService.getBackupPath(id);

            res.download(filePath);
        } catch (error) {
            res.status(404).json({
                success: false,
                message: "Backup not found.",
            });
        }
    }

    static delete(req: Request, res: Response) {
        try {
            const id = String(req.params.id);

            BackupService.deleteBackup(id);

            res.json({
                success: true,
                message: "Backup deleted successfully.",
            });
        } catch (error) {
            res.status(500).json({
                success: false,
                message: "Failed to delete backup.",
            });
        }
    }
}