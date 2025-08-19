console.log('🔍 Debug Logout - Checking authentication system...');

// Check if customKeycloakService is available
if (window.customKeycloakService) {
    console.log('✅ Custom Keycloak Service available');

    // Check current authentication state
    const isAuth = window.customKeycloakService.isAuthenticated();
    console.log('📋 Is Authenticated:', isAuth);

    if (isAuth) {
        const user = window.customKeycloakService.getCurrentUser();
        console.log('👤 Current User:', user);

        // Test logout function
        console.log('🚪 Testing logout...');
        window.customKeycloakService.logout()
            .then(() => {
                console.log('✅ Logout successful');
                console.log('🔄 Checking auth state after logout:', window.customKeycloakService.isAuthenticated());
                console.log('🏠 Redirecting to login...');
                window.location.href = '/custom-login';
            })
            .catch(error => {
                console.error('❌ Logout failed:', error);
            });
    } else {
        console.log('ℹ️ User is not authenticated');
    }
} else {
    console.log('❌ Custom Keycloak Service not available');
    console.log('Available globals:', Object.keys(window).filter(k => k.includes('custom') || k.includes('keycloak')));
}

// Also check localStorage
console.log('🗂️ Checking localStorage tokens:');
console.log('- keycloak_token:', localStorage.getItem('keycloak_token') ? 'EXISTS' : 'NOT FOUND');
console.log('- keycloak_refresh_token:', localStorage.getItem('keycloak_refresh_token') ? 'EXISTS' : 'NOT FOUND');
