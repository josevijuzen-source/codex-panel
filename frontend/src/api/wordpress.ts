import api from "./axios";

export interface InstallWordPressRequest {
  websiteId: number;
}

export async function installWordPress(
  data: InstallWordPressRequest
) {
  const response = await api.post(
    "/wordpress/install",
    data
  );

  return response.data;
}

export async function removeWordPress(
  websiteId: number
) {
  const response = await api.delete(
    `/wordpress/${websiteId}`
  );

  return response.data;
}