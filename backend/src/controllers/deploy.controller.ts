import { Request, Response } from "express";
import websiteDeployService from "../services/website.deploy.service";

class DeployController {
  async deploy(req: Request, res: Response) {
    try {
      const { domain, ownerId } = req.body;

      if (typeof domain !== "string" || domain.trim() === "") {
        return res.status(400).json({
          success: false,
          message: "Domain is required.",
        });
      }

      if (ownerId === undefined || ownerId === null) {
        return res.status(400).json({
          success: false,
          message: "Owner ID is required.",
        });
      }

      const result = await websiteDeployService.deploy(
        domain.trim(),
        Number(ownerId)
      );

      if (!result.success) {
        return res.status(400).json(result);
      }

      return res.status(201).json(result);
    } catch (error: any) {
      console.error(error);

      return res.status(500).json({
        success: false,
        message: error?.message || "Internal Server Error",
      });
    }
  }

  async remove(req: Request, res: Response) {
    try {
      const rawDomain = req.params.domain;

      const domain = Array.isArray(rawDomain)
        ? rawDomain[0]
        : rawDomain;

      if (!domain) {
        return res.status(400).json({
          success: false,
          message: "Domain is required.",
        });
      }

      const result = await websiteDeployService.remove(domain);

      if (!result.success) {
        return res.status(404).json(result);
      }

      return res.status(200).json(result);
    } catch (error: any) {
      console.error(error);

      return res.status(500).json({
        success: false,
        message: error?.message || "Internal Server Error",
      });
    }
  }
}

export default new DeployController();