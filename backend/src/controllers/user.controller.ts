import { Request, Response } from "express";
import prisma from "../lib/prisma";



export async function getUsers(req: Request, res: Response) {
  try {
    const users = await prisma.user.findMany({
      select: {
        id: true,
        name: true,
        email: true,
        role: true,
        cpuLimit: true,
        ramLimit: true,
        diskLimit: true,
        websiteLimit: true,
      },
    });

    

    res.json({
      success: true,
      users,
    });
  } catch (err) {
    console.error(err);

    res.status(500).json({
      success: false,
      message: "Failed to fetch users",
    });
  }
}

export async function updateUserLimits(req: Request, res: Response) {
  try {
    const { id } = req.params;
    const {
      cpuLimit,
      ramLimit,
      diskLimit,
      websiteLimit,
      role,
    } = req.body;

    const user = await prisma.user.update({
      where: {
        id: Number(id),
      },
      data: {
        cpuLimit,
        ramLimit,
        diskLimit,
        websiteLimit,
        role,
      },
    });

    res.json({
      success: true,
      message: "User updated successfully",
      user,
    });
  } catch (err) {
    console.error(err);

    res.status(500).json({
      success: false,
      message: "Failed to update user",
    });
  }
}

export async function deleteUser(req: Request, res: Response) {
  try {
    const { id } = req.params;

    await prisma.user.delete({
      where: {
        id: Number(id),
      },
    });

    res.json({
      success: true,
      message: "User deleted successfully",
    });
  } catch (err) {
    console.error(err);

    res.status(500).json({
      success: false,
      message: "Failed to delete user",
    });
  }
}