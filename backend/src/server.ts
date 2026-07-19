import app from "./app";
import fileRoutes from "./routes/files.routes";
import backupRoutes from "./routes/backup.routes";
app.use("/api/backups", backupRoutes);
const PORT = process.env.PORT || 5000;

app.listen(PORT, () => {
  console.log(`🚀 Codex Panel API running on http://localhost:${PORT}`);
});