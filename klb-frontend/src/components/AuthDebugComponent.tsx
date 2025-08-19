import React from 'react';
import useKeycloakAuth from '../hooks/useKeycloakAuth';
import keycloakConfig from '../config/keycloak';

export const AuthDebugComponent: React.FC = () => {
    const { isAuthenticated, loading, error, user, login } = useKeycloakAuth();

    return (
        <div style={{
            padding: '20px',
            border: '1px solid #ddd',
            borderRadius: '8px',
            margin: '20px',
            backgroundColor: '#f9f9f9',
            fontFamily: 'monospace',
            fontSize: '12px'
        }}>
            <h3>🔧 Authentication Debug Info</h3>

            <div style={{ marginBottom: '10px' }}>
                <strong>Authentication Status:</strong>
                <div>✅ Is Authenticated: {isAuthenticated ? 'YES' : 'NO'}</div>
                <div>⏳ Loading: {loading ? 'YES' : 'NO'}</div>
                <div>❌ Error: {error ? error.message : 'None'}</div>
                <div>👤 User: {user ? JSON.stringify(user, null, 2) : 'Not logged in'}</div>
            </div>

            <div style={{ marginBottom: '10px' }}>
                <strong>Keycloak Configuration:</strong>
                <pre style={{ fontSize: '10px', overflow: 'auto' }}>
                    {JSON.stringify(keycloakConfig, null, 2)}
                </pre>
            </div>

            <div style={{ marginBottom: '10px' }}>
                <strong>Current URL:</strong>
                <div>{window.location.href}</div>
            </div>

            <div>
                <button
                    onClick={() => {
                        console.log('Testing Keycloak login...');
                        login();
                    }}
                    style={{
                        padding: '8px 16px',
                        backgroundColor: '#1976d2',
                        color: 'white',
                        border: 'none',
                        borderRadius: '4px',
                        cursor: 'pointer',
                        marginRight: '10px'
                    }}
                >
                    🔐 Test Login
                </button>

                <button
                    onClick={() => {
                        // Test Keycloak endpoint
                        const authUrl = `${keycloakConfig.authority}/.well-known/openid_configuration`;
                        fetch(authUrl)
                            .then(response => response.json())
                            .then(data => {
                                console.log('Keycloak endpoint test result:', data);
                                alert('Keycloak endpoint is reachable! Check console for details.');
                            })
                            .catch(error => {
                                console.error('Keycloak endpoint test failed:', error);
                                alert('Keycloak endpoint is NOT reachable! Error: ' + error.message);
                            });
                    }}
                    style={{
                        padding: '8px 16px',
                        backgroundColor: '#f57c00',
                        color: 'white',
                        border: 'none',
                        borderRadius: '4px',
                        cursor: 'pointer'
                    }}
                >
                    🌐 Test Keycloak Endpoint
                </button>
            </div>
        </div>
    );
};

export default AuthDebugComponent;
