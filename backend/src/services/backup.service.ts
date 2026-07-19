import fs from "fs";
import path from "path";

const BACKUP_DIR = path.join(process.cwd(), "backups");

// Create backups directory if it doesn't exist
if (!fs.existsSync(BACKUP_DIR)) {
    fs.mkdirSync(BACKUP_DIR, { recursive: true });
}

export interface Backup {
    id: string;
    name: string;
    size: string;
    createdAt: string;
    status: "Completed";
}

export class BackupService {
    // Get all backups
    static getBackups(): Backup[] {
        const files = fs.readdirSync(BACKUP_DIR);

        return files.map((file) => {
            const filePath = path.join(BACKUP_DIR, file);
            const stats = fs.statSync(filePath);

            return {
                id: file,
                name: file,
                size: `${(stats.size / 1024 / 1024).toFixed(2)} MB`,
                createdAt: stats.birthtime.toLocaleString(),
                status: "Completed",
            };
        });
    }

    // Create a dummy backup (replace with real ZIP creation later)
    static createBackup() {
        const fileName = `backup-${Date.now()}.zip`;
        const filePath = path.join(BACKUP_DIR, fileName);

        fs.writeFileSync(
            filePath,
            `Codex Panel Backup\nCreated: ${new Date().toISOString()}`
        );

        return {
            success: true,
            fileName,
        };
    }

    // Delete a backup
    static deleteBackup(id: string): { success: boolean } {
        const filePath = path.join(BACKUP_DIR, id);

        if (!fs.existsSync(filePath)) {
            throw new Error("Backup not found.");
        }

        fs.unlinkSync(filePath);

        return {
            success: true,
        };
    }

    // Download backup path
    static getBackupPath(id: string): string {
        const filePath = path.join(BACKUP_DIR, id);

        if (!fs.existsSync(filePath)) {
            throw new Error("Backup not found.");
        }

        return filePath;
    }
}