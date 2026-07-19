import bcrypt from "bcrypt";
import prisma from "./lib/prisma";

async function main() {
  const password = await bcrypt.hash("admin123", 10);

  await prisma.user.upsert({
    where: {
      email: "admin@codexpanel.com",
    },
    update: {},
    create: {
      name: "Administrator",
      email: "admin@codexpanel.com",
      password,
      role: "ADMIN",
    },
  });

  console.log("✅ Admin created");
}

main()
  .catch(console.error)
  .finally(async () => {
    await prisma.$disconnect();
  });