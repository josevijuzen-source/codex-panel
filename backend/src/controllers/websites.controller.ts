import { Request, Response } from "express";
import { deployWebsite } from "../services/deploy.service";
import prisma from "../lib/prisma";

import {
  startWebsite as startWebsiteService,
  stopWebsite as stopWebsiteService,
  restartWebsite as restartWebsiteService,
} from "../services/website.service";

/* GET ALL WEBSITES */
export const getWebsites = async (req: Request, res: Response) => {
  try {
    const websites = await prisma.website.findMany({
      include: {
        owner: true,
      },
      orderBy: {
        createdAt: "desc",
      },
    });

    return res.json({
      success: true,
      websites,
    });
  } catch (error) {
    console.error(error);

    return res.status(500).json({
      success: false,
      message: "Failed to fetch websites",
    });
  }
};

/* GET SINGLE WEBSITE */
export const getWebsite = async (
  req: Request,
  res: Response
) => {
  try {
    const id = Number(req.params.id);

    const website = await prisma.website.findUnique({
      where: {
        id,
      },
      include: {
        owner: {
          select: {
            id: true,
            name: true,
            email: true,
          },
        },
      },
    });

    if (!website) {
      return res.status(404).json({
        success: false,
        message: "Website not found",
      });
    }

    return res.json({
      success: true,
      website,
    });
  } catch (error) {
    console.error(error);

    return res.status(500).json({
      success: false,
      message: "Failed to fetch website",
    });
  }
};

/* CREATE WEBSITE */
export const createWebsite = async (req: Request, res: Response) => {
  try {
    const {
  name,
  domain,
  runtime,
  cpu,
  ram,
  disk,
  ssl,
  ownerId,
} = req.body;

    // Validate required fields
  if (!name || !domain) {
  return res.status(400).json({
    success: false,
    message: "Website name and domain are required",
  });
}

    // Check if domain already exists
    const existingWebsite = await prisma.website.findUnique({
      where: {
        domain,
      },
    });

    if (existingWebsite) {
      return res.status(400).json({
        success: false,
        message: "Domain already exists",
      });
    }

    // Save website to database
    const website = await prisma.website.create({
      data: {
        name,
        domain,
        runtime,

        cpu: Number(cpu),
        ram: Number(ram),
        disk: Number(disk),

        ssl: Boolean(ssl),

        ownerId: Number(ownerId),

        status: "Stopped",

        rootPath: `/var/www/${domain}`,

        forceHttps: false,

        cpuUsage: 0,
        ramUsage: 0,
        diskUsage: 0,
      },
    });

    // Deploy website
    await deployWebsite({
      domain: website.domain,
    });

    return res.status(201).json({
      success: true,
      message: "Website created successfully",
      website,
    });
  } catch (error) {
    console.error(error);

    return res.status(500).json({
      success: false,
      message: error instanceof Error ? error.message : "Failed to create website",
    });
  }
};

/* START WEBSITE */
export const startWebsite = async (
  req: Request,
  res: Response
) => {
  try {
    const website = await prisma.website.update({
      where: {
        id: Number(req.params.id),
      },
      data: {
        status: "Running",
      },
    });

    await startWebsiteService(website.domain);

    return res.json({
      success: true,
      message: `${website.domain} started successfully`,
      website,
    });
  } catch (error) {
    console.error(error);

    return res.status(500).json({
      success: false,
      message: "Failed to start website",
    });
  }
};

/* STOP WEBSITE */
export const stopWebsite = async (
  req: Request,
  res: Response
) => {
  try {
    const website = await prisma.website.update({
      where: {
        id: Number(req.params.id),
      },
      data: {
        status: "Stopped",
      },
    });

    await stopWebsiteService(website.domain);

    return res.json({
      success: true,
      message: `${website.domain} stopped successfully`,
      website,
    });
  } catch (error) {
    console.error(error);

    return res.status(500).json({
      success: false,
      message: "Failed to stop website",
    });
  }
};

/* RESTART WEBSITE */
export const restartWebsite = async (
  req: Request,
  res: Response
) => {
  try {
    const website = await prisma.website.update({
      where: {
        id: Number(req.params.id),
      },
      data: {
        status: "Running",
      },
    });

    await restartWebsiteService(website.domain);

    return res.json({
      success: true,
      message: `${website.domain} restarted successfully`,
      website,
    });
  } catch (error) {
    console.error(error);

    return res.status(500).json({
      success: false,
      message: "Failed to restart website",
    });
  }
};

/* DELETE WEBSITE */
export const deleteWebsite = async (
  req: Request,
  res: Response
) => {
  try {
    await prisma.website.delete({
      where: {
        id: Number(req.params.id),
      },
    });

    return res.json({
      success: true,
      message: "Website deleted successfully",
    });
  } catch (error) {
    console.error(error);

    return res.status(500).json({
      success: false,
      message: "Failed to delete website",
    });
  }
};