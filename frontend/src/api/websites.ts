import axios from "./axios";

export interface CreateWebsiteRequest {
  name: string;
  domain: string;
  runtime: string;
  version?: string;
  cpu: number;
  ram: number;
  disk: number;
  ownerId: number;
}

export const getWebsites = async () => {
  const { data } = await axios.get("/websites");
  return data;
};

export const createWebsite = async (
  payload: CreateWebsiteRequest
) => {
  const { data } = await axios.post("/websites", payload);
  return data;
};

export const startWebsite = async (id: number) => {
  const { data } = await axios.post(`/websites/${id}/start`);
  return data;
};

export const stopWebsite = async (id: number) => {
  const { data } = await axios.post(`/websites/${id}/stop`);
  return data;
};

export const restartWebsite = async (id: number) => {
  const { data } = await axios.post(`/websites/${id}/restart`);
  return data;
};

export const deleteWebsite = async (id: number) => {
  const { data } = await axios.delete(`/websites/${id}`);
  return data;
};

export const deployWebsite = async (
  domain: string,
  ownerId: number
) => {
  const { data } = await axios.post("/deploy", {
    domain,
    ownerId,
  });

  return data;
};

export const installWordPress = async (
  websiteId: number
) => {
  const { data } = await axios.post(
    "/wordpress/install",
    {
      websiteId,
    }
  );

  return data;
};

export const removeWordPress = async (
  websiteId: number
) => {
  const { data } = await axios.delete(
    `/wordpress/${websiteId}`
  );

  return data;
};