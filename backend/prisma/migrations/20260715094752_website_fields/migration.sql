/*
  Warnings:

  - Added the required column `rootPath` to the `Website` table without a default value. This is not possible if the table is not empty.

*/
-- RedefineTables
PRAGMA defer_foreign_keys=ON;
PRAGMA foreign_keys=OFF;
CREATE TABLE "new_Website" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "name" TEXT NOT NULL,
    "domain" TEXT NOT NULL,
    "runtime" TEXT NOT NULL DEFAULT 'Node.js',
    "version" TEXT,
    "rootPath" TEXT NOT NULL,
    "nginxConfig" TEXT,
    "cpu" INTEGER NOT NULL DEFAULT 1,
    "ram" INTEGER NOT NULL DEFAULT 1024,
    "disk" INTEGER NOT NULL DEFAULT 10240,
    "ssl" BOOLEAN NOT NULL DEFAULT false,
    "forceHttps" BOOLEAN NOT NULL DEFAULT false,
    "status" TEXT NOT NULL DEFAULT 'Stopped',
    "pid" INTEGER,
    "port" INTEGER,
    "cpuUsage" REAL NOT NULL DEFAULT 0,
    "ramUsage" REAL NOT NULL DEFAULT 0,
    "diskUsage" REAL NOT NULL DEFAULT 0,
    "ownerId" INTEGER NOT NULL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL,
    CONSTRAINT "Website_ownerId_fkey" FOREIGN KEY ("ownerId") REFERENCES "User" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);
INSERT INTO "new_Website" ("cpu", "createdAt", "disk", "domain", "id", "name", "ownerId", "ram", "runtime", "ssl", "status", "updatedAt") SELECT "cpu", "createdAt", "disk", "domain", "id", "name", "ownerId", "ram", "runtime", "ssl", "status", "updatedAt" FROM "Website";
DROP TABLE "Website";
ALTER TABLE "new_Website" RENAME TO "Website";
CREATE UNIQUE INDEX "Website_domain_key" ON "Website"("domain");
PRAGMA foreign_keys=ON;
PRAGMA defer_foreign_keys=OFF;
