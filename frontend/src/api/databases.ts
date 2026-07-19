import axios from "axios";

const API = axios.create({
  baseURL: "http://localhost:5000/api",
  withCredentials: true,
});

export interface Database {
  id: number;
  name: string;
  username: string;
  password?: string;
  size: string;
  websiteId?: number | null;
  createdAt?: string;
  updatedAt?: string;
}

export interface CreateDatabaseData {
  name: string;
  username: string;
  password: string;
}

export async function getDatabases(): Promise<Database[]> {
  const { data } = await API.get("/databases");
  return data.databases ?? [];
}

export async function getDatabase(id: number): Promise<Database> {
  const { data } = await API.get(`/databases/${id}`);
  return data.database;
}

export async function createDatabase(
  payload: CreateDatabaseData
): Promise<Database> {
  const { data } = await API.post("/databases", payload);
  return data.database;
}

export async function updateDatabasePassword(
  id: number,
  password: string
): Promise<Database> {
  const { data } = await API.put(`/databases/${id}/password`, {
    password,
  });

  return data.database;
}

export async function deleteDatabase(id: number): Promise<void> {
  await API.delete(`/databases/${id}`);
}