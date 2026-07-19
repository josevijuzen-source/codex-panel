import { Router } from "express";
import deployController from "../controllers/deploy.controller";

const router = Router();

/**
 * Deploy a new website
 * POST /api/deploy
 */
router.post("/", (req, res) => deployController.deploy(req, res));

/**
 * Delete a deployed website
 * DELETE /api/deploy/:domain
 */
router.delete("/:domain", (req, res) =>
  deployController.remove(req, res)
);

export default router;