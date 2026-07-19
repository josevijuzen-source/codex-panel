import { Request, Response } from "express";
import databaseService from "../services/database.service";

class DatabaseController {
  async getAll(req: Request, res: Response) {
    try {
      const databases = await databaseService.getAll();

      return res.json({
        success: true,
        databases,
      });
    } catch (error) {
      console.error(error);

      return res.status(500).json({
        success: false,
        message: "Failed to fetch databases",
      });
    }
  }

  async getById(req: Request, res: Response) {
    try {
      const id = Number(req.params.id);

      const database = await databaseService.getById(id);

      if (!database) {
        return res.status(404).json({
          success: false,
          message: "Database not found",
        });
      }

      return res.json({
        success: true,
        database,
      });
    } catch (error) {
      console.error(error);

      return res.status(500).json({
        success: false,
        message: "Failed to fetch database",
      });
    }
  }

  async create(req: Request, res: Response) {
    try {
      const { name, username, password } = req.body;

      const database = await databaseService.create({
        name,
        username,
        password,
      });

      return res.status(201).json({
        success: true,
        message: "Database created successfully",
        database,
      });
    } catch (error) {
      console.error(error);

      return res.status(500).json({
        success: false,
        message: "Failed to create database",
      });
    }
  }

  async updatePassword(req: Request, res: Response) {
    try {
      const id = Number(req.params.id);
      const { password } = req.body;

      const database = await databaseService.updatePassword(
        id,
        password
      );

      return res.json({
        success: true,
        message: "Password updated successfully",
        database,
      });
    } catch (error) {
      console.error(error);

      return res.status(500).json({
        success: false,
        message: "Failed to update password",
      });
    }
  }

  async delete(req: Request, res: Response) {
    try {
      const id = Number(req.params.id);

      await databaseService.delete(id);

      return res.json({
        success: true,
        message: "Database deleted successfully",
      });
    } catch (error) {
      console.error(error);

      return res.status(500).json({
        success: false,
        message: "Failed to delete database",
      });
    }
  }
}

export default new DatabaseController();