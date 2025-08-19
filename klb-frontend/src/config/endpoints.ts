// Configuration for API endpoints
export const API_CONFIG = {
    // Base URL for all API requests - defaults to API Gateway
    BASE_URL: process.env.REACT_APP_API_BASE_URL || 'http://localhost:8080',

    // API endpoints
    ENDPOINTS: {
        // Gateway routes - all requests go through the API Gateway
        HEALTH: '/api/health',

        // Customer service routes (via gateway)
        CUSTOMERS: '/api/customers',

        // Account management routes (via gateway)  
        ACCOUNTS: '/api/accounts',
        TRANSACTIONS: '/api/transactions',

        // Loan service routes (via gateway)
        LOANS: '/api/loans',

        // Notification service routes (via gateway)
        NOTIFICATIONS: '/api/notifications',

        // Auth endpoints
        AUTH: {
            LOGIN: '/api/auth/login',
            REGISTER: '/api/auth/register',
            REFRESH: '/api/auth/refresh'
        }
    },

    // Keycloak configuration
    KEYCLOAK: {
        // Use environment variable or default to localhost
        AUTHORITY: process.env.REACT_APP_KEYCLOAK_URL || 'http://localhost:8090/realms/Kienlongbank'
    }
};

// Helper function to get full URL
export const getApiUrl = (endpoint: string): string => {
    return `${API_CONFIG.BASE_URL}${endpoint}`;
};

// Export for backward compatibility
export default API_CONFIG;
