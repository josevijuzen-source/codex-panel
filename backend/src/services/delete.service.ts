import fs from "fs";
import path from "path";

export async function deleteItem(directory: string, name: string) {
  const fullPath = path.join(directory, name);

  if (!fs.existsSync(fullPath)) {
    throw new Error("File not found");
  }

  fs.rmSync(fullPath, {
    recursive: true,
    force: true,
  });

  return true;
}