import api from "./axios";

export const getUsers = () => api.get("/users");

export const createUser = (data: unknown) =>
  api.post("/users", data);

export const updateUser = (id: string, data: unknown) =>
  api.put(`/users/${id}`, data);

export const deleteUser = (id: string) =>
  api.delete(`/users/${id}`);