import React, { useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import useKeycloakAuth from '../hooks/useKeycloakAuth';

interface LoginPageProps {
    onLoginSuccess?: (token: string, username: string) => void;
    onSwitchToRegister?: () => void;
}

export const LoginPage: React.FC<LoginPageProps> = ({
    onLoginSuccess,
    onSwitchToRegister
}) => {
    const { isAuthenticated, login, loading, error } = useKeycloakAuth();
    const navigate = useNavigate();

    useEffect(() => {
        // If user is already authenticated, redirect to dashboard
        if (isAuthenticated) {
            navigate('/dashboard', { replace: true });
        }
    }, [isAuthenticated, navigate]);

    const handleKeycloakLogin = () => {
        // Store the current location so we can redirect back after login
        const returnUrl = new URLSearchParams(window.location.search).get('returnUrl') || '/dashboard';
        sessionStorage.setItem('returnUrl', returnUrl);

        // Redirect to Keycloak login
        login();
    };

    if (loading) {
        return (
            <div style={{
                display: 'flex',
                justifyContent: 'center',
                alignItems: 'center',
                height: '100vh',
                flexDirection: 'column',
                gap: '20px'
            }}>
                <div style={{
                    width: '50px',
                    height: '50px',
                    border: '5px solid #f3f3f3',
                    borderTop: '5px solid #1976d2',
                    borderRadius: '50%',
                    animation: 'spin 1s linear infinite'
                }}></div>
                <p style={{ fontSize: '18px', color: '#666' }}>
                    🔐 Loading authentication...
                </p>
                <style dangerouslySetInnerHTML={{
                    __html: `
                        @keyframes spin {
                            0% { transform: rotate(0deg); }
                            100% { transform: rotate(360deg); }
                        }
                    `
                }} />
            </div>
        );
    }

    return (
        <div style={{
            maxWidth: '400px',
            margin: '50px auto',
            padding: '30px',
            border: '1px solid #ddd',
            borderRadius: '8px',
            backgroundColor: '#fff',
            boxShadow: '0 2px 10px rgba(0,0,0,0.1)'
        }}>
            <h2 style={{
                textAlign: 'center',
                marginBottom: '30px',
                color: '#1976d2'
            }}>
                🏦 Welcome to KienLongBank
            </h2>

            <p style={{
                textAlign: 'center',
                marginBottom: '30px',
                color: '#666',
                fontSize: '16px'
            }}>
                Please sign in to access your account
            </p>

            {error && (
                <div style={{
                    backgroundColor: '#ffebee',
                    color: '#c62828',
                    padding: '12px',
                    borderRadius: '4px',
                    marginBottom: '20px',
                    border: '1px solid #ef9a9a'
                }}>
                    ❌ Authentication error: {error.message}
                </div>
            )}

            <button
                onClick={handleKeycloakLogin}
                disabled={loading}
                style={{
                    width: '100%',
                    padding: '12px',
                    backgroundColor: '#1976d2',
                    color: 'white',
                    border: 'none',
                    borderRadius: '4px',
                    fontSize: '16px',
                    cursor: loading ? 'not-allowed' : 'pointer',
                    opacity: loading ? 0.7 : 1,
                    marginBottom: '20px',
                    transition: 'background-color 0.3s ease'
                }}
                onMouseEnter={(e: React.MouseEvent<HTMLButtonElement>) => {
                    if (!loading) {
                        (e.target as HTMLButtonElement).style.backgroundColor = '#1565c0';
                    }
                }}
                onMouseLeave={(e: React.MouseEvent<HTMLButtonElement>) => {
                    if (!loading) {
                        (e.target as HTMLButtonElement).style.backgroundColor = '#1976d2';
                    }
                }}
            >
                {loading ? '🔄 Redirecting...' : '🔐 Sign In with Keycloak'}
            </button>

            <div style={{
                textAlign: 'center',
                marginTop: '20px',
                padding: '15px',
                backgroundColor: '#f5f5f5',
                borderRadius: '4px',
                fontSize: '14px',
                color: '#666'
            }}>
                <p style={{ margin: '0 0 8px 0', fontWeight: 'bold' }}>
                    🔒 Secure Authentication
                </p>
                <p style={{ margin: 0 }}>
                    You will be redirected to Keycloak for secure authentication.
                </p>
            </div>

            {onSwitchToRegister && (
                <div style={{
                    textAlign: 'center',
                    marginTop: '20px'
                }}>
                    <span style={{ color: '#666' }}>Don't have an account? </span>
                    <button
                        onClick={onSwitchToRegister}
                        style={{
                            background: 'none',
                            border: 'none',
                            color: '#1976d2',
                            cursor: 'pointer',
                            textDecoration: 'underline',
                            fontSize: '14px'
                        }}
                    >
                        Contact Administrator
                    </button>
                </div>
            )}
        </div>
    );
};