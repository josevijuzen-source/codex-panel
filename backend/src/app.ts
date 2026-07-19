import express from "express";
import cors from "cors";

import authRoutes from "./routes/auth.routes";
import userRoutes from "./routes/users.routes";
import websiteRoutes from "./routes/websites.routes";
import fileRoutes from "./routes/files.routes";
import uploadRoutes from "./routes/upload.routes";
import downloadRoutes from "./routes/download.routes";
import renameRoutes from "./routes/rename.routes";
import serverRoutes from "./routes/server.routes";
import backupRoutes from "./routes/backup.routes";
import systemRoutes from "./routes/system.routes";
import databaseRoutes from "./routes/database.routes";
import wordpressRoutes from "./routes/wordpress.routes";
import monitorRoutes from "./routes/monitor.routes";
import dashboardRoutes from "./routes/dashboard.routes";
const app = express();

// Middleware
app.use(
  cors({
    origin: "http://localhost:5173",
    credentials: true,
  })
);

app.use(express.json());

// Root
app.get("/", (req, res) => {
  res.json({
    success: true,
    message: "Codex Panel API Running 🚀",
    version: "1.0.0",
  });
});

// API Routes
app.use("/api/auth", authRoutes);
app.use("/api/users", userRoutes);
app.use("/api/system", systemRoutes);
app.use("/api/websites", websiteRoutes);
app.use("/api/files", fileRoutes);
app.use("/api/upload", uploadRoutes);
app.use("/api/download", downloadRoutes);
app.use("/api/wordpress", wordpressRoutes);
app.use("/api/databases", databaseRoutes);
app.use("/api/rename", renameRoutes);
app.use("/api/monitor", monitorRoutes);
app.use("/api/server", serverRoutes);
app.use("/api/backups", backupRoutes);
app.use("/api/websites", websiteRoutes);
app.use("/api/wordpress", wordpressRoutes);
app.use("/api/dashboard", dashboardRoutes);

export default app;