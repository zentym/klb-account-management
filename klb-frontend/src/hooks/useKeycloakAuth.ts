import { useAuth as useOidcAuth } from 'react-oidc-context';
import { jwtDecode } from 'jwt-decode';

interface JwtPayload {
    sub: string;
    preferred_username?: string;
    email?: string;
    name?: string;
    realm_access?: {
        roles: string[];
    };
    resource_access?: {
        [key: string]: {
            roles: string[];
        };
    };
    exp?: number;
    iat?: number;
}

export const useKeycloakAuth = () => {
    const auth = useOidcAuth();

    // Extract user roles from JWT token
    const getUserRoles = (): string[] => {
        if (!auth.user?.access_token) {
            console.log('No access token available');
            return [];
        }

        try {
            const decoded: JwtPayload = jwtDecode(auth.user.access_token);
            console.log('Decoded JWT token:', decoded);

            // Get realm roles
            const realmRoles = decoded.realm_access?.roles || [];
            console.log('Realm roles:', realmRoles);

            // Get client roles (if needed)
            const clientRoles: string[] = [];
            if (decoded.resource_access) {
                Object.values(decoded.resource_access).forEach(client => {
                    clientRoles.push(...client.roles);
                });
            }
            console.log('Client roles:', clientRoles);

            const allRoles = [...realmRoles, ...clientRoles];
            console.log('All roles combined:', allRoles);
            return allRoles;
        } catch (error) {
            console.error('Error decoding JWT token:', error);
            return [];
        }
    };

    // Check if user has a specific role
    const hasRole = (role: string): boolean => {
        const roles = getUserRoles();
        console.log(`Checking role '${role}':`, {
            allRoles: roles,
            hasDirectRole: roles.includes(role),
            hasRolePrefix: roles.includes(`ROLE_${role}`),
            result: roles.includes(role) || roles.includes(`ROLE_${role}`)
        });
        return roles.includes(role) || roles.includes(`ROLE_${role}`);
    };

    // Check if user is admin
    const isAdmin = (): boolean => {
        return hasRole('ADMIN') || hasRole('admin');
    };

    // Get username from token
    const getUsername = (): string | null => {
        if (!auth.user?.access_token) return null;

        try {
            const decoded: JwtPayload = jwtDecode(auth.user.access_token);
            return decoded.preferred_username || decoded.sub || null;
        } catch (error) {
            console.error('Error getting username from token:', error);
            return null;
        }
    };

    // Get user info from token
    const getUserInfo = () => {
        if (!auth.user?.access_token) return null;

        try {
            const decoded: JwtPayload = jwtDecode(auth.user.access_token);
            return {
                username: decoded.preferred_username || decoded.sub,
                email: decoded.email,
                name: decoded.name,
                roles: getUserRoles(),
            };
        } catch (error) {
            console.error('Error getting user info from token:', error);
            return null;
        }
    };

    return {
        // Original OIDC auth properties
        ...auth,

        // Custom helper methods
        hasRole,
        isAdmin,
        getUsername,
        getUserInfo,
        getUserRoles,

        // Aliases for compatibility with existing code
        isAuthenticated: auth.isAuthenticated,
        user: getUsername(),
        userInfo: getUserInfo(),
        token: auth.user?.access_token || null,
        loading: auth.isLoading,

        // Login/logout methods that redirect to Keycloak
        login: () => auth.signinRedirect(),
        logout: () => auth.signoutRedirect(),
    };
};

export default useKeycloakAuth;
