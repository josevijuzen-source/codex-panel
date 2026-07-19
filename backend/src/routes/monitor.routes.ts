import { Router } from "express";
import { getMonitor } from "../controllers/monitor.controller";

const router = Router();

/* GET SERVER MONITOR */
router.get("/", getMonitor);

export default router;