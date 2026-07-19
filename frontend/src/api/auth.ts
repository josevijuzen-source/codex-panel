import api from "./axios";

export const login = (data: {
  email: string;
  password: string;
}) => api.post("/auth/login", data);

export const logout = () => api.post("/auth/logout");

export const me = () => api.get("/auth/me");