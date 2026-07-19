import { Request, Response } from "express";
import { exec } from "child_process";
import { promisify } from "util";

const execAsync = promisify(exec);

export const executeCommand = async (
  req: Request,
  res: Response
) => {
  try {
    const { command } = req.body;

    const { stdout, stderr } = await execAsync(command);

    return res.json({
      success: true,
      output: stdout || stderr,
    });
  } catch (error: any) {
    return res.json({
      success: false,
      output: error.stderr || error.message,
    });
  }
};