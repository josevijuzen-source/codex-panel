import { Request, Response } from "express";
import wordpressService from "../services/wordpress.service";

class WordPressController {
  async install(req: Request, res: Response) {
    try {
      const { websiteId } = req.body;

      if (!websiteId) {
        return res.status(400).json({
          success: false,
          message: "Website ID is required.",
        });
      }

      const result = await wordpressService.install(Number(websiteId));

      return res.status(200).json(result);
    } catch (error: any) {
      console.error(error);

      return res.status(500).json({
        success: false,
        message: error.message || "Internal Server Error",
      });
    }
  }

  async remove(req: Request, res: Response) {
    try {
      const { websiteId } = req.params;

      if (!websiteId) {
        return res.status(400).json({
          success: false,
          message: "Website ID is required.",
        });
      }

      const result = await wordpressService.remove(Number(websiteId));

      return res.status(200).json(result);
    } catch (error: any) {
      console.error(error);

      return res.status(500).json({
        success: false,
        message: error.message || "Internal Server Error",
      });
    }
  }
}

export default new WordPressController();