import axios from "./axios";

export const getMonitor = async () => {
  const { data } = await axios.get("/monitor");
  return data;
};