// Keycloak configuration for different environments
export const keycloakConfig = {
    // Development configuration (local)
    development: {
        authority: 'http://localhost:8090/realms/Kienlongbank',
        client_id: 'klb-frontend',
        redirect_uri: window.location.origin + '/callback',
        post_logout_redirect_uri: window.location.origin,
        response_type: 'code',
        scope: 'openid profile email',
        automaticSilentRenew: true,
        includeIdTokenInSilentRenew: true,
        loadUserInfo: true,
    },

    // Production configuration (with Docker containers)
    production: {
        authority: 'http://keycloak:8080/realms/Kienlongbank',
        client_id: 'klb-frontend',
        redirect_uri: window.location.origin + '/callback',
        post_logout_redirect_uri: window.location.origin,
        response_type: 'code',
        scope: 'openid profile email',
        automaticSilentRenew: true,
        includeIdTokenInSilentRenew: true,
        loadUserInfo: true,
    }
};

// Get configuration based on environment
export const getKeycloakConfig = () => {
    const isProduction = process.env.NODE_ENV === 'production';
    return isProduction ? keycloakConfig.production : keycloakConfig.development;
};

export default getKeycloakConfig();
