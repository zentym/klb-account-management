import React, { useState } from 'react';
import AuthFlow from './components/AuthFlow';
import Dashboard from './components/Dashboard';
import './App.css';

interface User {
    phoneNumber: string;
    fullName?: string;
    email?: string;
    registeredAt?: string;
    loginAt?: string;
    rememberMe?: boolean;
    otpVerified?: boolean;
}

function CompletePhoneApp() {
    const [currentUser, setCurrentUser] = useState<User | null>(null);
    const [isAuthenticated, setIsAuthenticated] = useState<boolean>(false);

    const handleAuthSuccess = (user: User, type: 'login' | 'register') => {
        console.log(`${type} successful:`, user);
        setCurrentUser(user);
        setIsAuthenticated(true);
    };

    const handleLogout = () => {
        setCurrentUser(null);
        setIsAuthenticated(false);
        console.log('User logged out');
    };

    return (
        <div className="complete-phone-app">
            {isAuthenticated && currentUser ? (
                <Dashboard />
            ) : (
                <AuthFlow
                    onAuthSuccess={handleAuthSuccess}
                />
            )}
        </div>
    );
}

export default CompletePhoneApp;
