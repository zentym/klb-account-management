/**
 * TypeScript definitions for JWT authentication system
 * 
 * This file defines the expected structure of JWT tokens and user objects
 * used throughout the KLB Account Management frontend application.
 */

/**
 * Expected payload structure of JWT tokens from the backend
 */
export interface JwtTokenPayload {
    /** Subject - typically the username */
    sub: string;

    /** User role (e.g., 'ADMIN', 'USER', 'MANAGER') */
    role: string;

    /** Issued at time (Unix timestamp) */
    iat?: number;

    /** Expiration time (Unix timestamp) */
    exp?: number;

    /** Issuer */
    iss?: string;

    /** Audience */
    aud?: string;
}

/**
 * User information stored in localStorage
 */
export interface UserInfo {
    /** Username */
    username: string;

    /** User role */
    role: string;
}

/**
 * Authentication response from login API
 */
export interface LoginResponse {
    /** JWT token */
    token: string;

    /** Username */
    username: string;

    /** Optional token expiration time in seconds */
    expiresIn?: number;
}

/**
 * Available user roles in the system
 */
export type UserRole = 'ADMIN' | 'USER' | 'MANAGER' | 'CUSTOMER_SERVICE';

/**
 * Helper type for role-based access control
 */
export interface RolePermissions {
    /** Can access admin features */
    canAccessAdmin: boolean;

    /** Can manage users */
    canManageUsers: boolean;

    /** Can view all transactions */
    canViewAllTransactions: boolean;

    /** Can modify system settings */
    canModifySettings: boolean;
}

/**
 * Utility function to get permissions based on role
 */
export const getRolePermissions = (role: UserRole): RolePermissions => {
    switch (role) {
        case 'ADMIN':
            return {
                canAccessAdmin: true,
                canManageUsers: true,
                canViewAllTransactions: true,
                canModifySettings: true
            };
        case 'MANAGER':
            return {
                canAccessAdmin: false,
                canManageUsers: true,
                canViewAllTransactions: true,
                canModifySettings: false
            };
        case 'CUSTOMER_SERVICE':
            return {
                canAccessAdmin: false,
                canManageUsers: false,
                canViewAllTransactions: true,
                canModifySettings: false
            };
        case 'USER':
        default:
            return {
                canAccessAdmin: false,
                canManageUsers: false,
                canViewAllTransactions: false,
                canModifySettings: false
            };
    }
};
