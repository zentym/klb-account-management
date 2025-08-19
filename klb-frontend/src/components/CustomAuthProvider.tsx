import React, { createContext, useContext, useEffect, useState, ReactNode } from 'react';
import customKeycloakService from '../services/customKeycloakService';

interface UserInfo {
    username: string;
    email?: string;
    name?: string;
    roles: string[];
    token: string;
    refreshToken: string;
}

interface CustomAuthContextType {
    user: UserInfo | null;
    loading: boolean;
    error: string | null;
    isAuthenticated: boolean;
    login: (username: string, password: string) => Promise<UserInfo>;
    logout: () => Promise<void>;
    hasRole: (role: string) => boolean;
    isAdmin: () => boolean;
    getToken: () => string | null;
}

const CustomAuthContext = createContext<CustomAuthContextType | undefined>(undefined);

interface CustomAuthProviderProps {
    children: ReactNode;
}

export const CustomAuthProvider: React.FC<CustomAuthProviderProps> = ({ children }) => {
    const [user, setUser] = useState<UserInfo | null>(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);

    // Initialize auth state on mount
    useEffect(() => {
        const initAuth = () => {
            try {
                const currentUser = customKeycloakService.getCurrentUser();
                setUser(currentUser);
            } catch (err) {
                console.error('Error initializing auth:', err);
                setError('Failed to initialize authentication');
            } finally {
                setLoading(false);
            }
        };

        initAuth();
    }, []);

    const login = async (username: string, password: string): Promise<UserInfo> => {
        setLoading(true);
        setError(null);

        try {
            const userInfo = await customKeycloakService.login(username, password);
            setUser(userInfo);
            return userInfo;
        } catch (err) {
            const errorMessage = err instanceof Error ? err.message : 'Login failed';
            setError(errorMessage);
            throw err;
        } finally {
            setLoading(false);
        }
    };

    const logout = async (): Promise<void> => {
        setLoading(true);
        try {
            await customKeycloakService.logout();
            setUser(null);
            setError(null);
        } catch (err) {
            console.error('Logout error:', err);
            // Still clear user state even if logout API fails
            setUser(null);
        } finally {
            setLoading(false);
        }
    };

    const hasRole = (role: string): boolean => {
        return customKeycloakService.hasRole(role);
    };

    const isAdmin = (): boolean => {
        return customKeycloakService.isAdmin();
    };

    const getToken = (): string | null => {
        return customKeycloakService.getToken();
    };

    const contextValue: CustomAuthContextType = {
        user,
        loading,
        error,
        isAuthenticated: !!user,
        login,
        logout,
        hasRole,
        isAdmin,
        getToken,
    };

    return (
        <CustomAuthContext.Provider value={contextValue}>
            {children}
        </CustomAuthContext.Provider>
    );
};

// Custom hook to use auth context
export const useCustomAuth = (): CustomAuthContextType => {
    const context = useContext(CustomAuthContext);
    if (context === undefined) {
        throw new Error('useCustomAuth must be used within a CustomAuthProvider');
    }
    return context;
};

export default CustomAuthProvider;
