import { Router } from "express";
import { getServerStats } from "../controllers/server.controller";

const router = Router();

router.get("/stats", getServerStats);

export default router;