import mysql from "mysql2/promise";
import dotenv from "dotenv";

dotenv.config();

const pool = mysql.createPool({
  host: process.env.MYSQL_HOST || "127.0.0.1",
  port: Number(process.env.MYSQL_PORT || 3306),
  user: process.env.MYSQL_USER || "root",
  password: process.env.MYSQL_PASSWORD || "",
  waitForConnections: true,
  connectionLimit: 10,
});

class MySQLService {
  async createDatabase(
    database: string,
    username: string,
    password: string
  ) {
    const conn = await pool.getConnection();

    try {
      await conn.query(
        `CREATE DATABASE IF NOT EXISTS \`${database}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci`
      );

      await conn.query(
        `CREATE USER IF NOT EXISTS ?@'%' IDENTIFIED BY ?`,
        [username, password]
      );

      await conn.query(
        `ALTER USER ?@'%' IDENTIFIED BY ?`,
        [username, password]
      );

      await conn.query(
        `GRANT ALL PRIVILEGES ON \`${database}\`.* TO ?@'%'`,
        [username]
      );

      await conn.query(`FLUSH PRIVILEGES`);
    } finally {
      conn.release();
    }
  }

  async deleteDatabase(database: string, username: string) {
    const conn = await pool.getConnection();

    try {
      await conn.query(`DROP DATABASE IF EXISTS \`${database}\``);

      await conn.query(`DROP USER IF EXISTS ?@'%'`, [username]);

      await conn.query(`FLUSH PRIVILEGES`);
    } finally {
      conn.release();
    }
  }

  async changePassword(username: string, password: string) {
    const conn = await pool.getConnection();

    try {
      await conn.query(
        `ALTER USER ?@'%' IDENTIFIED BY ?`,
        [username, password]
      );

      await conn.query(`FLUSH PRIVILEGES`);
    } finally {
      conn.release();
    }
  }

  async getDatabases() {
    const conn = await pool.getConnection();

    try {
      const [rows] = await conn.query(
        `SHOW DATABASES`
      );

      return rows;
    } finally {
      conn.release();
    }
  }

  async testConnection() {
    const conn = await pool.getConnection();

    try {
      await conn.ping();
      return true;
    } catch {
      return false;
    } finally {
      conn.release();
    }
  }
}

export default new MySQLService();