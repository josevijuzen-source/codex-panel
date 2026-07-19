import axios from "./axios";

export const getDashboard = async () => {
  const { data } = await axios.get("/dashboard");
  return data;
};