import { useState, useEffect } from 'react';
import customKeycloakService from '../services/customKeycloakService';

interface CustomAuthHook {
    isAuthenticated: boolean;
    userInfo: any;
    loading: boolean;
    hasRole: (role: string) => boolean;
    logout: () => void;
    refreshAuthState: () => void;
}

export const useCustomAuth = (): CustomAuthHook => {
    const [isAuthenticated, setIsAuthenticated] = useState(false);
    const [userInfo, setUserInfo] = useState<any>(null);
    const [loading, setLoading] = useState(true);

    const refreshAuthState = () => {
        setLoading(true);
        try {
            const authenticated = customKeycloakService.isAuthenticated();
            setIsAuthenticated(authenticated);

            if (authenticated) {
                const user = customKeycloakService.getCurrentUser();
                setUserInfo(user);
                console.log('Custom Auth - User authenticated:', user);
            } else {
                setUserInfo(null);
                console.log('Custom Auth - User not authenticated');
            }
        } catch (error) {
            console.error('Custom Auth - Error checking authentication:', error);
            setIsAuthenticated(false);
            setUserInfo(null);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        // Initial check
        refreshAuthState();

        // Listen for storage changes (when token is updated in another tab)
        const handleStorageChange = (e: StorageEvent) => {
            if (e.key === 'keycloak_token' || e.key === 'keycloak_refresh_token') {
                refreshAuthState();
            }
        };

        window.addEventListener('storage', handleStorageChange);

        // Check token validity periodically
        const interval = setInterval(() => {
            const authenticated = customKeycloakService.isAuthenticated();
            if (authenticated !== isAuthenticated) {
                refreshAuthState();
            }
        }, 30000); // Check every 30 seconds

        return () => {
            window.removeEventListener('storage', handleStorageChange);
            clearInterval(interval);
        };
    }, []);

    const hasRole = (role: string): boolean => {
        if (!userInfo?.roles) return false;

        // Check for exact role match or case-insensitive match
        return userInfo.roles.some((userRole: string) =>
            userRole === role ||
            userRole.toLowerCase() === role.toLowerCase()
        );
    };

    const logout = async () => {
        try {
            setLoading(true);
            await customKeycloakService.logout();
            setIsAuthenticated(false);
            setUserInfo(null);
            // Redirect to login page
            window.location.href = '/custom-login';
        } catch (error) {
            console.error('Custom Auth - Logout error:', error);
        } finally {
            setLoading(false);
        }
    };

    return {
        isAuthenticated,
        userInfo,
        loading,
        hasRole,
        logout,
        refreshAuthState
    };
};

export default useCustomAuth;
