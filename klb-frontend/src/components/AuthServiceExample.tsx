import React from 'react';
import { authService } from '../services/authService';
import api from '../config/api';

/**
 * Example component showing how to use AuthService and API
 */
export const AuthServiceExample: React.FC = () => {

    // Example: Using AuthService methods
    const handleLogin = async () => {
        try {
            const result = await authService.login('testuser', 'password123');
            console.log('Login successful:', result);
        } catch (error) {
            console.error('Login failed:', error);
        }
    };

    const handleRegister = async () => {
        try {
            const result = await authService.register('newuser', 'password123');
            console.log('Registration successful:', result);
        } catch (error) {
            console.error('Registration failed:', error);
        }
    };

    const handleLogout = () => {
        authService.logout();
        console.log('User logged out');
    };

    const checkAuthStatus = () => {
        const isAuth = authService.isAuthenticated();
        const token = authService.getToken();
        const user = authService.getCurrentUser();
        const userInfo = authService.getUserInfo();
        const userRole = authService.getUserRole();
        const isAdmin = authService.isAdmin();

        console.log('Authentication status:', {
            isAuthenticated: isAuth,
            token,
            user,
            userInfo,
            userRole,
            isAdmin
        });
    };

    // Example: Making authenticated API calls
    const fetchProtectedData = async () => {
        try {
            // Token will be automatically added by the interceptor
            const response = await api.get('/api/customers');
            console.log('Protected data:', response.data);
        } catch (error) {
            console.error('Failed to fetch protected data:', error);
        }
    };

    const createCustomer = async () => {
        try {
            const newCustomer = {
                fullName: 'John Doe',
                email: 'john@example.com',
                phone: '123-456-7890',
                address: '123 Main St'
            };

            // Token will be automatically added by the interceptor
            const response = await api.post('/api/customers', newCustomer);
            console.log('Customer created:', response.data);
        } catch (error) {
            console.error('Failed to create customer:', error);
        }
    };

    return (
        <div style={{ padding: '20px' }}>
            <h3>AuthService Example</h3>

            <div style={{ marginBottom: '20px' }}>
                <h4>Authentication Methods:</h4>
                <button onClick={handleLogin} style={{ margin: '5px' }}>
                    Test Login
                </button>
                <button onClick={handleRegister} style={{ margin: '5px' }}>
                    Test Register
                </button>
                <button onClick={handleLogout} style={{ margin: '5px' }}>
                    Logout
                </button>
                <button onClick={checkAuthStatus} style={{ margin: '5px' }}>
                    Check Auth Status
                </button>
            </div>

            <div>
                <h4>API Calls (with auto token):</h4>
                <button onClick={fetchProtectedData} style={{ margin: '5px' }}>
                    Fetch Customers
                </button>
                <button onClick={createCustomer} style={{ margin: '5px' }}>
                    Create Customer
                </button>
            </div>

            <div style={{ marginTop: '20px', fontSize: '12px', color: '#666' }}>
                <p>Check browser console for output</p>
            </div>
        </div>
    );
};

export default AuthServiceExample;
