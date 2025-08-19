import React, { useState, useEffect } from 'react';
import useCustomAuth from '../hooks/useCustomAuth';
import Navigation from './Navigation';
import { healthCheck } from '../config/api';

interface LayoutProps {
    children: React.ReactNode;
}

export const Layout: React.FC<LayoutProps> = ({ children }) => {
    const { isAuthenticated, userInfo, logout } = useCustomAuth();
    const [backendStatus, setBackendStatus] = useState<string>('Connecting...');
    const [isBackendConnected, setIsBackendConnected] = useState<boolean>(false);

    useEffect(() => {
        const checkBackendConnection = async () => {
            try {
                const data = await healthCheck();
                // Check if health check returned an error status
                if (data.status && data.status.includes('❌')) {
                    setBackendStatus(data.status);
                    setIsBackendConnected(false);
                } else {
                    setBackendStatus(data.status || 'Backend is running!');
                    setIsBackendConnected(true);
                }
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

    return (
        <div className="App">
            <header style={{
                backgroundColor: '#1976d2',
                color: 'white',
                padding: '20px',
                marginBottom: '0'
            }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <h1>🏦 Kien Long Bank - Account Management System</h1>
                    {isAuthenticated && (
                        <div style={{ display: 'flex', alignItems: 'center', gap: '15px' }}>
                            <span>Chào, <strong>{userInfo?.username}</strong> ({userInfo?.roles?.join(', ') || 'User'})</span>
                            <button
                                onClick={logout}
                                style={{
                                    padding: '8px 16px',
                                    backgroundColor: '#f44336',
                                    color: 'white',
                                    border: 'none',
                                    borderRadius: '4px',
                                    cursor: 'pointer'
                                }}
                            >
                                Đăng xuất
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

            {/* Navigation hiển thị khi đã đăng nhập (không phụ thuộc backend status) */}
            {isAuthenticated && <Navigation />}

            <main style={{ padding: '0 20px' }}>
                {children}
            </main>
        </div>
    );
};

export default Layout;
