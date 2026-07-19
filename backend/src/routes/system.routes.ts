import { Router } from "express";
import systemController from "../controllers/system.controller";

const router = Router();

/**
 * GET /api/system
 * Get live system statistics
 */
router.get("/", (req, res) => systemController.getStats(req, res));

export default router;