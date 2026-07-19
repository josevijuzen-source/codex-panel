import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();

export interface CreateDatabaseInput {
  name: string;
  username: string;
  password: string;
}

class DatabaseService {
  async getAll() {
    return prisma.database.findMany({
      orderBy: {
        id: "desc",
      },
    });
  }

  async getById(id: number) {
    return prisma.database.findUnique({
      where: {
        id,
      },
    });
  }

  async create(data: CreateDatabaseInput) {
    return prisma.database.create({
      data: {
        name: data.name,
        username: data.username,
        password: data.password,
        size: "0 MB",
      },
    });
  }

  async updatePassword(id: number, password: string) {
    return prisma.database.update({
      where: {
        id,
      },
      data: {
        password,
      },
    });
  }

  async delete(id: number) {
    return prisma.database.delete({
      where: {
        id,
      },
    });
  }
}

export default new DatabaseService();