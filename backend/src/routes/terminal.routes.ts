import { Router } from "express";
import { exec } from "child_process";

const router = Router();

router.post("/execute", (req, res) => {
  const { command } = req.body;

  if (!command) {
    return res.status(400).json({
      success: false,
      output: "No command provided",
    });
  }

  exec(command, (error, stdout, stderr) => {
    if (error) {
      return res.json({
        success: false,
        output: stderr || error.message,
      });
    }

    return res.json({
      success: true,
      output: stdout || "(No output)",
    });
  });
});

export default router;