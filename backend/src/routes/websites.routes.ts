import { Router } from "express";

import {
  createWebsite,
  getWebsites,
  getWebsite,
  startWebsite,
  stopWebsite,
  restartWebsite,
  deleteWebsite,
} from "../controllers/websites.controller";

const router = Router();

/* GET */
router.get("/", getWebsites);
router.get("/:id", getWebsite);

/* CREATE */
router.post("/", createWebsite);

/* ACTIONS */
router.post("/:id/start", startWebsite);
router.post("/:id/stop", stopWebsite);
router.post("/:id/restart", restartWebsite);

/* DELETE */
router.delete("/:id", deleteWebsite);

export default router;