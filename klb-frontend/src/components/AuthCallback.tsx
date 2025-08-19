import React, { useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from 'react-oidc-context';

const AuthCallback: React.FC = () => {
    const auth = useAuth();
    const navigate = useNavigate();

    useEffect(() => {
        const handleCallback = async () => {
            if (auth.isAuthenticated) {
                // User is authenticated, redirect to dashboard or intended page
                const returnUrl = sessionStorage.getItem('returnUrl') || '/dashboard';
                sessionStorage.removeItem('returnUrl');
                navigate(returnUrl, { replace: true });
            } else if (auth.error) {
                // Handle authentication error
                console.error('Authentication error:', auth.error);
                navigate('/login', { replace: true });
            }
            // If still loading, do nothing - the loading state will be handled
        };

        handleCallback();
    }, [auth.isAuthenticated, auth.error, navigate]);

    if (auth.isLoading) {
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
                    🔐 Completing authentication...
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

    if (auth.error) {
        return (
            <div style={{
                display: 'flex',
                justifyContent: 'center',
                alignItems: 'center',
                height: '100vh',
                flexDirection: 'column',
                gap: '20px'
            }}>
                <h2 style={{ color: '#d32f2f' }}>❌ Authentication Error</h2>
                <p style={{ color: '#666', textAlign: 'center', maxWidth: '500px' }}>
                    There was an error during authentication. Please try again.
                </p>
                <p style={{ color: '#999', fontSize: '14px' }}>
                    Error: {auth.error.message}
                </p>
                <button
                    onClick={() => navigate('/login')}
                    style={{
                        padding: '10px 20px',
                        backgroundColor: '#1976d2',
                        color: 'white',
                        border: 'none',
                        borderRadius: '4px',
                        cursor: 'pointer'
                    }}
                >
                    Return to Login
                </button>
            </div>
        );
    }

    // This should not normally be reached, but just in case
    return (
        <div style={{
            display: 'flex',
            justifyContent: 'center',
            alignItems: 'center',
            height: '100vh'
        }}>
            <p>Redirecting...</p>
        </div>
    );
};

export default AuthCallback;
