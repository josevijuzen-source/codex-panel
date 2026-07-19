import axios from "./axios";

export const renameFile = async (
  path: string,
  oldName: string,
  newName: string
) => {
  const response = await axios.post("/files/rename", {
    path,
    oldName,
    newName,
  });

  return response.data;
};

export const downloadFile = (
  filePath: string
) => {
  window.open(
    `/api/download?path=${encodeURIComponent(filePath)}`,
    "_blank"
  );
};

export const getFiles = async (
  path: string,
  websiteId?: string
) => {
  const { data } = await axios.get("/files", {
    params: {
      path,
      websiteId,
    },
  });

  return data;
};

export const createFolder = async (
  directory: string,
  folderName: string
) => {
  const { data } = await axios.post("/files/folder", {
    directory,
    folderName,
  });


  
  return data;
};
export const deleteFile = async (
  path: string,
  name: string
) => {
  const res = await fetch("http://localhost:5000/api/files", {
    method: "DELETE",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      path,
      name,
    }),
  });

  return res.json();
};