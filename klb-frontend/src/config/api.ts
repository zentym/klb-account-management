import axios, { AxiosInstance, AxiosRequestConfig, AxiosResponse } from 'axios';
import customKeycloakService from '../services/customKeycloakService';

// API configuration - Use environment variable or fallback to proxy
const API_CONFIG = {
    baseURL: process.env.REACT_APP_API_BASE_URL || '/',
    timeout: 10000, // 10 seconds
    headers: {
        'Content-Type': 'application/json',
    },
};

// Create axios instance
const api: AxiosInstance = axios.create(API_CONFIG);

// Token key constants (legacy)
const TOKEN_KEY = 'jwtToken';

// Request interceptor to add auth token
api.interceptors.request.use(
    (config: any) => {
        // Priority: Custom Keycloak Service > Legacy localStorage/sessionStorage
        let token = customKeycloakService.getToken();

        // Fallback to legacy storage if custom service doesn't have token
        if (!token) {
            token = localStorage.getItem(TOKEN_KEY) || sessionStorage.getItem(TOKEN_KEY);
        }

        if (token && config.headers) {
            config.headers.Authorization = `Bearer ${token}`;
        }

        // Log request for debugging (remove in production)
        console.log(`🚀 API Request: ${config.method?.toUpperCase()} ${config.url}`, {
            headers: config.headers,
            data: config.data,
            hasToken: !!token,
            tokenSource: localStorage.getItem(TOKEN_KEY) ? 'localStorage' :
                sessionStorage.getItem(TOKEN_KEY) ? 'sessionStorage' : 'none'
        });

        return config;
    },
    (error) => {
        console.error('❌ Request interceptor error:', error);
        return Promise.reject(error);
    }
);

// Response interceptor to handle common responses and errors
api.interceptors.response.use(
    (response: AxiosResponse) => {
        // Log successful response (remove in production)
        console.log(`✅ API Response: ${response.config.method?.toUpperCase()} ${response.config.url}`, {
            status: response.status,
            data: response.data
        });

        return response;
    },
    (error) => {
        console.error('❌ API Error:', error.response?.status, error.response?.data);

        // Handle specific error cases
        if (error.response) {
            const { status, data } = error.response;

            switch (status) {
                case 401:
                    // Unauthorized - token might be expired or invalid
                    console.warn('🔐 Unauthorized access - clearing stored tokens');
                    localStorage.removeItem(TOKEN_KEY);
                    sessionStorage.removeItem(TOKEN_KEY);
                    localStorage.removeItem('username');
                    sessionStorage.removeItem('username');

                    // Redirect to login page or trigger logout
                    // You can dispatch a custom event or use your routing solution
                    window.dispatchEvent(new CustomEvent('auth:unauthorized'));
                    break;

                case 403:
                    // Forbidden - user doesn't have permission
                    console.warn('🚫 Access forbidden');
                    break;

                case 404:
                    // Not found
                    console.warn('🔍 Resource not found');
                    break;

                case 422:
                    // Validation error
                    console.warn('📝 Validation error:', data);
                    break;

                case 500:
                    // Server error
                    console.error('🔥 Server error');
                    break;

                default:
                    console.error(`🚨 Unexpected error: ${status}`);
            }
        } else if (error.request) {
            // Network error
            console.error('🌐 Network error - no response received');
        } else {
            // Other error
            console.error('⚠️ Unexpected error:', error.message);
        }

        return Promise.reject(error);
    }
);

// Utility function to set auth token manually (if needed)
export const setAuthToken = (token: string | null): void => {
    if (token) {
        api.defaults.headers.common['Authorization'] = `Bearer ${token}`;
    } else {
        delete api.defaults.headers.common['Authorization'];
    }
};

// Utility function to clear auth token
export const clearAuthToken = (): void => {
    delete api.defaults.headers.common['Authorization'];
    localStorage.removeItem(TOKEN_KEY);
    sessionStorage.removeItem(TOKEN_KEY);
    localStorage.removeItem('username');
    sessionStorage.removeItem('username');
};

// Health check function - without authentication
export const healthCheck = async (): Promise<{ status: string; timestamp: string }> => {
    try {
        // Create a separate axios instance without auth for health check
        const response = await axios.get('/api/health', {
            timeout: 5000,
            headers: {
                'Content-Type': 'application/json',
            }
        });
        return response.data;
    } catch (error) {
        console.warn('Health check failed:', error);
        // Return a fallback status instead of throwing
        return {
            status: '❌ Backend connection failed',
            timestamp: new Date().toISOString()
        };
    }
};

export default api;
