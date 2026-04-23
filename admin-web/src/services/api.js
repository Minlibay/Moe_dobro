import axios from 'axios';

const API_URL = 'http://127.0.0.1:3003/api';

const api = axios.create({
  baseURL: API_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Interceptor для добавления токена
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('admin_token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error)
);

// Interceptor для обработки ошибок
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      localStorage.removeItem('admin_token');
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);

// Auth
export const login = async (phone, password) => {
  const response = await api.post('/auth/login', { phone, password });
  if (response.data.token) {
    localStorage.setItem('admin_token', response.data.token);
  }
  return response.data;
};

export const logout = () => {
  localStorage.removeItem('admin_token');
  window.location.href = '/login';
};

export const getProfile = async () => {
  const response = await api.get('/auth/profile');
  return response.data;
};

// Admin API
export const getStats = async () => {
  const response = await api.get('/admin/stats');
  return response.data;
};

export const getUsers = async (params = {}) => {
  const response = await api.get('/admin/users', { params });
  return response.data;
};

export const verifyUser = async (userId, isVerified) => {
  const response = await api.patch(`/admin/users/${userId}/verify`, { is_verified: isVerified });
  return response.data;
};

export const blockUser = async (userId, isBlocked, blockReason) => {
  const response = await api.patch(`/admin/users/${userId}/block`, { is_blocked: isBlocked, block_reason: blockReason });
  return response.data;
};

export const getFundraisers = async (params = {}) => {
  const response = await api.get('/admin/fundraisers', { params });
  return response.data;
};

export const closeFundraiser = async (fundraiserId) => {
  const response = await api.patch(`/admin/fundraisers/${fundraiserId}/close`);
  return response.data;
};

export const featureFundraiser = async (fundraiserId, isFeatured) => {
  const response = await api.patch(`/admin/fundraisers/${fundraiserId}/feature`, { is_featured: isFeatured });
  return response.data;
};

export const verifyCompletion = async (fundraiserId) => {
  const response = await api.patch(`/admin/fundraisers/${fundraiserId}/verify-completion`);
  return response.data;
};

export const deleteFundraiser = async (fundraiserId) => {
  const response = await api.delete(`/admin/fundraisers/${fundraiserId}`);
  return response.data;
};

export const getDonations = async (params = {}) => {
  const response = await api.get('/admin/donations', { params });
  return response.data;
};

export const approveDonation = async (donationId) => {
  const response = await api.patch(`/admin/donations/${donationId}/approve`);
  return response.data;
};

export const rejectDonation = async (donationId, reason) => {
  const response = await api.patch(`/admin/donations/${donationId}/reject`, { reason });
  return response.data;
};

export default api;
