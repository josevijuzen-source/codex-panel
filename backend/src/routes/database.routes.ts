import { Router } from "express";
import databaseController from "../controllers/database.controller";

const router = Router();

// Get all databases
router.get("/", (req, res) => databaseController.getAll(req, res));

// Get database by ID
router.get("/:id", (req, res) => databaseController.getById(req, res));

// Create database
router.post("/", (req, res) => databaseController.create(req, res));

// Update database password
router.put("/:id/password", (req, res) =>
  databaseController.updatePassword(req, res)
);

// Delete database
router.delete("/:id", (req, res) =>
  databaseController.delete(req, res)
);

export default router;