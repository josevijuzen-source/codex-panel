import { Router } from "express";

import {
  getUsers,
  updateUserLimits,
  deleteUser,
} from "../controllers/user.controller";

import {
  authenticate,
  authorize,
} from "../middleware/auth.middleware";

const router = Router();

router.use(authenticate);
router.use(authorize("ADMIN"));

router.get("/", getUsers);
router.put("/:id", updateUserLimits);
router.delete("/:id", deleteUser);

export default router;