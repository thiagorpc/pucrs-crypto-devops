// src/api.ts
import axios from 'axios';

const API_BASE_URL = 'http://localhost:3000'; // ajuste para sua API

export const api = axios.create({
  baseURL: API_BASE_URL,
});

// Health check
export const getHealth = async () => {
  const response = await api.get('/health');
  return response.data;
};

// Encriptar dado
export const encryptData = async (payload: string) => {
  const response = await api.post('/security/encrypt', { payload });
  return response.data;
};
