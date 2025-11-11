// src/api.ts
import axios from 'axios';

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:3000';

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

// Descriptografar dado
export const decryptData = async (encrypted: string) => {
  const response = await api.post('/security/decrypt', { encrypted });
  return response.data;
};
