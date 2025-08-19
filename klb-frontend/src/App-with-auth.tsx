import React, { useState, useEffect } from 'react';
import './App.css';
import { CustomerPage } from './components/CustomerPage';
import TransferPage from './components/TransferPage';
import { LoginPage } from './components/LoginPage';
import { RegisterPage } from './components/RegisterPage';
import { KeycloakAuthProvider } from './components/KeycloakAuthProvider';
import useKeycloakAuth from './hooks/useKeycloakAuth';

// Main App component that handles authentication
const AppContent: React.FC = () => {
    const { isAuthenticated, user, logout, loading } = useKeycloakAuth();
    const [backendStatus, setBackendStatus] = useState<string>('Connecting...');
    const [isBackendConnected, setIsBackendConnected] = useState<boolean>(false);
    const [showRegister, setShowRegister] = useState<boolean>(false);

    useEffect(() => {
        const checkBackendConnection = async () => {
            try {
                const response = await fetch('/api/health');
                const data = await response.json();
                setBackendStatus(data.status || 'Backend is running!');
                setIsBackendConnected(true);
            } catch (error) {
                console.error("Error fetching backend health: ", error);
                setBackendStatus('❌ Failed to connect to backend. Please ensure the backend server is running on http://localhost:8080');
                setIsBackendConnected(false);
            }
        };

        checkBackendConnection();

        // Check backend health every 30 seconds
        const interval = setInterval(checkBackendConnection, 30000);

        return () => clearInterval(interval);
    }, []);

    const handleLoginSuccess = (token: string, username: string) => {
        // The AuthProvider will handle the login state
        console.log('Login successful for user:', username);
    };

    const handleRegisterSuccess = () => {
        setShowRegister(false);
        console.log('Registration successful, switching to login');
    };

    const handleLogout = () => {
        logout();
    };

    // Show loading spinner while checking auth status
    if (loading) {
        return (
            <div style={{
                display: 'flex',
                justifyContent: 'center',
                alignItems: 'center',
                height: '100vh',
                fontSize: '18px',
                color: '#666'
            }}>
                🔄 Loading...
            </div>
        );
    }

    return (
        <div className="App">
            <header style={{
                backgroundColor: '#1976d2',
                color: 'white',
                padding: '20px',
                marginBottom: '20px'
            }}>
                <div style={{
                    display: 'flex',
                    justifyContent: 'space-between',
                    alignItems: 'center'
                }}>
                    <h1>🏦 Kien Long Bank - Account Management System</h1>
                    {isAuthenticated && (
                        <div style={{
                            display: 'flex',
                            alignItems: 'center',
                            gap: '15px'
                        }}>
                            <span style={{ fontSize: '14px' }}>
                                Welcome, <strong>{user}</strong>
                            </span>
                            <button
                                onClick={handleLogout}
                                style={{
                                    padding: '8px 15px',
                                    backgroundColor: '#f44336',
                                    color: 'white',
                                    border: 'none',
                                    borderRadius: '4px',
                                    cursor: 'pointer',
                                    fontSize: '14px'
                                }}
                            >
                                Logout
                            </button>
                        </div>
                    )}
                </div>

                <div style={{
                    padding: '10px',
                    backgroundColor: isBackendConnected ? '#4caf50' : '#f44336',
                    borderRadius: '4px',
                    marginTop: '10px'
                }}>
                    <strong>Backend Status:</strong> {backendStatus}
                </div>

                {!isBackendConnected && (
                    <div style={{
                        padding: '10px',
                        backgroundColor: '#ff9800',
                        borderRadius: '4px',
                        marginTop: '10px',
                        fontSize: '14px'
                    }}>
                        <strong>🔧 Setup Instructions:</strong>
                        <ol style={{ textAlign: 'left', margin: '5px 0' }}>
                            <li>Start PostgreSQL: <code>docker-compose up -d</code></li>
                            <li>Start Backend: <code>./mvnw spring-boot:run</code></li>
                            <li>Refresh this page</li>
                        </ol>
                    </div>
                )}
            </header>

            <main>
                {!isBackendConnected ? (
                    <div style={{
                        textAlign: 'center',
                        padding: '40px',
                        color: '#666'
                    }}>
                        <h3>⏳ Waiting for backend connection...</h3>
                        <p>Please start the backend server and refresh the page.</p>
                    </div>
                ) : !isAuthenticated ? (
                    // Show authentication forms
                    <div>
                        {showRegister ? (
                            <RegisterPage
                                onRegisterSuccess={handleRegisterSuccess}
                                onSwitchToLogin={() => setShowRegister(false)}
                            />
                        ) : (
                            <LoginPage
                                onLoginSuccess={handleLoginSuccess}
                                onSwitchToRegister={() => setShowRegister(true)}
                            />
                        )}
                    </div>
                ) : (
                    // Show main application content
                    <div>
                        <CustomerPage />
                        <TransferPage />
                    </div>
                )}
            </main>
        </div>
    );
};

// Wrapper component that provides authentication context
function App() {
    return (
        <KeycloakAuthProvider>
            <AppContent />
        </KeycloakAuthProvider>
    );
}

export default App;
