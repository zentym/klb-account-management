import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import { authService, User } from '../services/authService';
import { setAuthToken, clearAuthToken } from '../config/api';

interface AuthContextType {
    isAuthenticated: boolean;
    user: string | null;
    userInfo: User | null;
    token: string | null;
    login: (token: string, username: string) => void;
    logout: () => void;
    loading: boolean;
    hasRole: (role: string) => boolean;
    isAdmin: () => boolean;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const useAuth = () => {
    const context = useContext(AuthContext);
    if (context === undefined) {
        throw new Error('useAuth must be used within an AuthProvider');
    }
    return context;
};

interface AuthProviderProps {
    children: ReactNode;
}

export const AuthProvider: React.FC<AuthProviderProps> = ({ children }) => {
    const [isAuthenticated, setIsAuthenticated] = useState<boolean>(false);
    const [user, setUser] = useState<string | null>(null);
    const [userInfo, setUserInfo] = useState<User | null>(null);
    const [token, setToken] = useState<string | null>(null);
    const [loading, setLoading] = useState<boolean>(true);

    useEffect(() => {
        // Check for existing token on app startup
        const checkAuthStatus = () => {
            console.log('🔍 Checking auth status on startup...');

            const isAuth = authService.isAuthenticated();
            const storedToken = authService.getToken();
            const storedUsername = authService.getCurrentUser();
            const storedUserInfo = authService.getUserInfo();

            console.log('📊 Auth status check results:', {
                isAuthenticated: isAuth,
                hasToken: !!storedToken,
                hasUsername: !!storedUsername,
                hasUserInfo: !!storedUserInfo,
                userRole: storedUserInfo?.role
            });

            if (isAuth && storedToken && storedUsername) {
                // Set auth token in API config
                setAuthToken(storedToken);

                setToken(storedToken);
                setUser(storedUsername);
                setUserInfo(storedUserInfo);
                setIsAuthenticated(true);

                console.log('✅ Auth restored from storage');
            } else {
                console.log('❌ No valid auth found in storage');
            }

            setLoading(false);
        };

        checkAuthStatus();

        // Listen for unauthorized events from API interceptor
        const handleUnauthorized = () => {
            logout();
        };

        window.addEventListener('auth:unauthorized', handleUnauthorized);

        return () => {
            window.removeEventListener('auth:unauthorized', handleUnauthorized);
        };
    }, []);

    const login = (newToken: string, username: string) => {
        console.log('🔑 AuthProvider.login called', { token: newToken?.substring(0, 20) + '...', username });

        // Set auth token in API config
        setAuthToken(newToken);

        setToken(newToken);
        setUser(username);

        // Set user info immediately from the username parameter
        // instead of trying to get it from storage
        setUserInfo({
            username: username,
            role: 'USER' // Will be updated when we get proper user info
        });

        // Then get proper user info from authService
        setTimeout(() => {
            const storedUserInfo = authService.getUserInfo();
            console.log('🔄 Updated user info from storage:', storedUserInfo);
            if (storedUserInfo) {
                setUserInfo(storedUserInfo);
            }
        }, 100);

        setIsAuthenticated(true);

        // Verify token is properly stored
        setTimeout(() => {
            const verifyToken = authService.getToken();
            console.log('✅ Token verification after login:', {
                stored: !!verifyToken,
                matches: verifyToken === newToken
            });
        }, 200);
    };

    const logout = () => {
        // Use authService to clear everything
        authService.logout();

        // Clear API auth token
        clearAuthToken();

        setToken(null);
        setUser(null);
        setUserInfo(null);
        setIsAuthenticated(false);
    };

    const hasRole = (role: string): boolean => {
        return authService.hasRole(role);
    };

    const isAdmin = (): boolean => {
        return authService.isAdmin();
    };

    const value: AuthContextType = {
        isAuthenticated,
        user,
        userInfo,
        token,
        login,
        logout,
        loading,
        hasRole,
        isAdmin
    };

    return (
        <AuthContext.Provider value={value}>
            {children}
        </AuthContext.Provider>
    );
};

export default AuthProvider;
