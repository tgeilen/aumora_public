import axios, { AxiosResponse, AxiosError } from 'axios';

// Define the base URL for our API
// Automatically detect if we're accessing from the network IP or localhost
const getApiUrl = () => {
  const hostname = window.location.hostname;
  const protocol = window.location.protocol;
  
  // For production (when not localhost), use the same protocol and domain without port
  if (hostname !== 'localhost' && hostname !== '127.0.0.1') {
    return `${protocol}//${hostname}/api/v1`;
  }
  
  // Default to localhost for local development
  return import.meta.env.VITE_API_URL || 'http://localhost:3000/api/v1';
};

const API_URL = getApiUrl();

// Create an axios instance with default config
const api = axios.create({
  baseURL: API_URL,
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json'
  },
  withCredentials: true, // Send cookies with cross-origin requests
});

// Request interceptor to add auth token to requests
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('auth_token');
    if (token && config.headers) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Response interceptor to handle common errors
api.interceptors.response.use(
  (response: AxiosResponse) => response,
  (error: AxiosError) => {
    console.error('API Error:', error.response?.data || error.message);
    
    // Handle authentication errors
    if (error.response?.status === 401) {
      localStorage.removeItem('auth_token');
      // Redirect to login page or show auth error
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);

export default api; 