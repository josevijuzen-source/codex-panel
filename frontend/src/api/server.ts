import axios from "./axios";

export const getServerStats = async () => {
  const { data } = await axios.get("/server/stats");
  return data;
};