import { Router } from "express";
import { downloadFile } from "../controllers/download.controller";

const router = Router();

router.get("/", downloadFile);

export default router;