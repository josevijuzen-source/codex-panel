import { Router } from "express";
import { renameFile } from "../controllers/rename.controller";

const router = Router();

router.post("/", renameFile);

export default router;