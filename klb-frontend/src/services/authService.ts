import api from '../config/api';
import { jwtDecode } from 'jwt-decode';

export interface LoginRequest {
    phoneNumber: string;
    password: string;
}

export interface RegisterRequest {
    phoneNumber: string;
    password: string;
}

export interface AuthResponse {
    token: string;
    username: string;
    expiresIn?: number;
}

export interface ApiError {
    message: string;
    status?: number;
}

// Định nghĩa kiểu dữ liệu cho thông tin người dùng trong JWT token
export interface JwtPayload {
    sub: string; // Subject, thường là username
    role: string; // Vai trò
    iat?: number; // Issued at time
    exp?: number; // Expiration time
}

// Định nghĩa kiểu dữ liệu cho user object được lưu trong localStorage
export interface User {
    username: string;
    role: string;
}

class AuthService {
    private readonly TOKEN_KEY = 'jwtToken';
    private readonly USERNAME_KEY = 'username';
    private readonly USER_KEY = 'user'; // New key for storing user object
    private readonly REFRESH_TOKEN_KEY = 'refreshToken';

    /**
     * Register a new user
     * @param phoneNumber - The phone number for the new user
     * @param password - The password for the new user
     * @returns Promise with authentication response
     */
    async register(phoneNumber: string, password: string): Promise<AuthResponse> {
        try {
            const request: RegisterRequest = { phoneNumber, password };
            const response = await api.post<AuthResponse>('/api/auth/register', request);

            return response.data;
        } catch (error: any) {
            throw this.handleError(error);
        }
    }

    /**
     * Login user
     * @param phoneNumber - The phone number
     * @param password - The password
     * @param rememberMe - Whether to use localStorage (true) or sessionStorage (false)
     * @returns Promise with authentication response
     */
    async login(phoneNumber: string, password: string, rememberMe: boolean = true): Promise<AuthResponse> {
        try {
            const request: LoginRequest = { phoneNumber, password };
            const response = await api.post<AuthResponse>('/api/auth/login', request);

            const { token } = response.data;

            if (token) {
                // Choose storage based on rememberMe preference
                const storage = rememberMe ? localStorage : sessionStorage;

                // Lưu token vào storage
                storage.setItem(this.TOKEN_KEY, token);

                // Giải mã token để lấy thông tin user
                const decodedUser: JwtPayload = jwtDecode(token);

                // Lưu đối tượng user vào storage
                const userInfo: User = {
                    username: decodedUser.sub,
                    role: decodedUser.role
                };

                storage.setItem(this.USER_KEY, JSON.stringify(userInfo));

                // Keep backward compatibility
                storage.setItem(this.USERNAME_KEY, decodedUser.sub);
            }

            return response.data;
        } catch (error: any) {
            throw this.handleError(error);
        }
    }

    /**
     * Logout user - clear all stored auth data
     */
    logout(): void {
        localStorage.removeItem(this.TOKEN_KEY);
        localStorage.removeItem(this.USERNAME_KEY);
        localStorage.removeItem(this.USER_KEY);
        localStorage.removeItem(this.REFRESH_TOKEN_KEY);
        sessionStorage.removeItem(this.TOKEN_KEY);
        sessionStorage.removeItem(this.USERNAME_KEY);
        sessionStorage.removeItem(this.USER_KEY);
        sessionStorage.removeItem(this.REFRESH_TOKEN_KEY);
    }

    /**
     * Get current token from storage
     * @returns JWT token or null if not found
     */
    getToken(): string | null {
        return localStorage.getItem(this.TOKEN_KEY) || sessionStorage.getItem(this.TOKEN_KEY);
    }

    /**
     * Get current username from storage
     * @returns Username or null if not found
     */
    getCurrentUser(): string | null {
        return localStorage.getItem(this.USERNAME_KEY) || sessionStorage.getItem(this.USERNAME_KEY);
    }

    /**
     * Get current user information from storage
     * @returns User object or null if not found
     */
    getUserInfo(): User | null {
        const userStr = localStorage.getItem(this.USER_KEY) || sessionStorage.getItem(this.USER_KEY);
        if (!userStr) return null;

        try {
            return JSON.parse(userStr) as User;
        } catch (error) {
            console.error('Error parsing user info from storage:', error);
            return null;
        }
    }

    /**
     * Get current user role
     * @returns User role or null if not found
     */
    getUserRole(): string | null {
        const userInfo = this.getUserInfo();
        return userInfo ? userInfo.role : null;
    }

    /**
     * Check if current user has a specific role
     * @param role - Role to check
     * @returns true if user has the role, false otherwise
     */
    hasRole(role: string): boolean {
        const userRole = this.getUserRole();
        return userRole === role;
    }

    /**
     * Check if current user is admin
     * @returns true if user is admin, false otherwise
     */
    isAdmin(): boolean {
        return this.hasRole('ADMIN');
    }

    /**
     * Check if user is authenticated
     * @returns true if token exists, false otherwise
     */
    isAuthenticated(): boolean {
        const token = this.getToken();
        if (!token) return false;

        // Check if token is expired (optional)
        try {
            const payload: JwtPayload = this.parseJwtPayload(token);
            const currentTime = Date.now() / 1000;

            // If token has expiration time and it's expired
            if (payload.exp && payload.exp < currentTime) {
                this.logout();
                return false;
            }

            return true;
        } catch (error) {
            // If token is malformed, consider it invalid
            this.logout();
            return false;
        }
    }

    /**
     * Save authentication data to storage
     * @param authData - Authentication response data
     * @param rememberMe - Whether to use localStorage (true) or sessionStorage (false)
     */
    saveAuthData(authData: AuthResponse, rememberMe: boolean = true): void {
        const storage = rememberMe ? localStorage : sessionStorage;
        const { token } = authData;

        storage.setItem(this.TOKEN_KEY, token);
        storage.setItem(this.USERNAME_KEY, authData.username);

        // Decode JWT and save user info
        try {
            const decodedUser: JwtPayload = jwtDecode(token);
            const userInfo: User = {
                username: decodedUser.sub,
                role: decodedUser.role
            };
            storage.setItem(this.USER_KEY, JSON.stringify(userInfo));
        } catch (error) {
            console.error('Error decoding token in saveAuthData:', error);
        }
    }

    /**
     * Refresh token (if your backend supports it)
     */
    async refreshToken(): Promise<AuthResponse> {
        try {
            const refreshToken = localStorage.getItem(this.REFRESH_TOKEN_KEY) ||
                sessionStorage.getItem(this.REFRESH_TOKEN_KEY);

            if (!refreshToken) {
                throw new Error('No refresh token available');
            }

            const response = await api.post<AuthResponse>('/api/auth/refresh', {
                refreshToken
            });

            const { token } = response.data;

            if (token) {
                // Update token
                localStorage.setItem(this.TOKEN_KEY, token);

                // Decode and update user info
                const decodedUser: JwtPayload = jwtDecode(token);
                const userInfo: User = {
                    username: decodedUser.sub,
                    role: decodedUser.role
                };

                localStorage.setItem(this.USER_KEY, JSON.stringify(userInfo));
                localStorage.setItem(this.USERNAME_KEY, decodedUser.sub);
            }

            return response.data;
        } catch (error: any) {
            this.logout();
            throw this.handleError(error);
        }
    }

    /**
     * Parse JWT payload (without verification - for client-side info only)
     * @param token - JWT token
     * @returns Parsed payload
     */
    private parseJwtPayload(token: string): JwtPayload {
        try {
            const base64Url = token.split('.')[1];
            const base64 = base64Url.replace(/-/g, '+').replace(/_/g, '/');
            const jsonPayload = decodeURIComponent(
                atob(base64)
                    .split('')
                    .map(c => '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2))
                    .join('')
            );
            return JSON.parse(jsonPayload) as JwtPayload;
        } catch (error) {
            throw new Error('Invalid token format');
        }
    }

    /**
     * Handle and format API errors
     * @param error - Axios error object
     * @returns Formatted error object
     */
    private handleError(error: any): ApiError {
        if (error.response) {
            // Server responded with error status
            const message = error.response.data?.message ||
                error.response.data?.error ||
                `Server error: ${error.response.status}`;
            return {
                message,
                status: error.response.status
            };
        } else if (error.request) {
            // Request was made but no response received
            return {
                message: 'Network error: Unable to connect to server'
            };
        } else {
            // Something else happened
            return {
                message: error.message || 'An unexpected error occurred'
            };
        }
    }
}

// Export singleton instance
export const authService = new AuthService();
export default authService;
