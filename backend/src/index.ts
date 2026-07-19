import express from "express";
import cors from "cors";
import backupRoutes from "./routes/backup.routes";

import terminalRoutes from "./routes/terminal.routes";
import databaseRoutes from "./routes/database.routes";
import monitorRoutes from "./routes/monitor.routes";



const app = express();
app.use("/api/databases", databaseRoutes);
app.use("/api/monitor", monitorRoutes);
app.use("/api/monitor", monitorRoutes);
app.use(cors());
app.use("/api/backups", backupRoutes);
app.use(express.json());

app.use("/api/terminal", terminalRoutes);

app.listen(5000, () => {
  console.log("Server running");
});