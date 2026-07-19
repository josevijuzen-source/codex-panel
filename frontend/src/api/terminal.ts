import axios from "./axios";

export const executeCommand = async (command: string) => {
  const { data } = await axios.post("/terminal/execute", {
    command,
  });

  return data;
};