import { Request, Response } from "express";

export const uploadFile = (
  req: Request,
  res: Response
) => {
  return res.json({
    success: true,
    file: req.file,
  });
};