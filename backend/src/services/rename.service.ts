import fs from "fs/promises";
import path from "path";

export async function renameItem(
  currentPath: string,
  oldName: string,
  newName: string
) {
  const oldFile = path.join(currentPath, oldName);
  const newFile = path.join(currentPath, newName);

  await fs.rename(oldFile, newFile);

  return true;
}