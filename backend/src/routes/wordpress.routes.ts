import { Router, Request, Response } from "express";
import wordpressController from "../controllers/wordpress.controller";

const router = Router();

/**
 * Test API
 * GET /api/wordpress
 */
router.get("/", (req: Request, res: Response) => {
  res.json({
    success: true,
    message: "WordPress API is working 🚀",
  });
});

/**
 * Test Install Route
 * GET /api/wordpress/install
 */
router.get("/install", (req: Request, res: Response) => {
  res.json({
    success: true,
    message:
      "Use POST /api/wordpress/install with { websiteId } to install WordPress.",
  });
});

/**
 * Install WordPress
 * POST /api/wordpress/install
 */
router.post("/install", (req: Request, res: Response) => {
  wordpressController.install(req, res);
});

/**
 * Remove WordPress
 * DELETE /api/wordpress/:websiteId
 */
router.delete("/:websiteId", (req: Request, res: Response) => {
  wordpressController.remove(req, res);
});

export default router;