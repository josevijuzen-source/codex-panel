import prisma from "../lib/prisma";

export async function getDashboardStats() {
  const websites = await prisma.website.count();
  const databases = await prisma.database.count();
  const users = await prisma.user.count();

  const running = await prisma.website.count({
    where: {
      status: "Running",
    },
  });

  return {
    websites,
    databases,
    users,
    running,
  };
}