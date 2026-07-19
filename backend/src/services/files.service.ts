import fs from "fs";
import path from "path";

/* LIST FILES */
export async function listFiles(directory: string) {
  if (!fs.existsSync(directory)) {
    fs.mkdirSync(directory, {
      recursive: true,
    });
  }

  const files = fs.readdirSync(directory);

  return files.map((file) => {
    const fullPath = path.join(directory, file);
    const stats = fs.statSync(fullPath);

    return {
      name: file,
      isDirectory: stats.isDirectory(),
      size: stats.size,
      modified: stats.mtime,
    };
  });
}

/* CREATE FOLDER */
export async function createFolder(
  directory: string,
  folderName: string
) {
  if (!fs.existsSync(directory)) {
    fs.mkdirSync(directory, {
      recursive: true,
    });
  }

  const folderPath = path.join(directory, folderName);

  if (!fs.existsSync(folderPath)) {
    fs.mkdirSync(folderPath, {
      recursive: true,
    });
  }

  return {
    success: true,
  };
}