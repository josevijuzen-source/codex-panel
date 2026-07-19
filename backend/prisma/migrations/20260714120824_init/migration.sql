-- CreateTable
CREATE TABLE "User" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "name" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "password" TEXT NOT NULL,
    "role" TEXT NOT NULL DEFAULT 'USER',
    "cpuLimit" INTEGER NOT NULL DEFAULT 1,
    "ramLimit" INTEGER NOT NULL DEFAULT 1024,
    "diskLimit" INTEGER NOT NULL DEFAULT 10240,
    "websiteLimit" INTEGER NOT NULL DEFAULT 1,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL
);

-- CreateTable
CREATE TABLE "Website" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "name" TEXT NOT NULL,
    "domain" TEXT NOT NULL,
    "runtime" TEXT NOT NULL DEFAULT 'Node.js',
    "cpu" INTEGER NOT NULL DEFAULT 1,
    "ram" INTEGER NOT NULL DEFAULT 1024,
    "disk" INTEGER NOT NULL DEFAULT 10240,
    "ssl" BOOLEAN NOT NULL DEFAULT false,
    "status" TEXT NOT NULL DEFAULT 'Stopped',
    "ownerId" INTEGER NOT NULL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL,
    CONSTRAINT "Website_ownerId_fkey" FOREIGN KEY ("ownerId") REFERENCES "User" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateIndex
CREATE UNIQUE INDEX "User_email_key" ON "User"("email");

-- CreateIndex
CREATE UNIQUE INDEX "Website_domain_key" ON "Website"("domain");
