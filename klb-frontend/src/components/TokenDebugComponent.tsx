import React, { useState } from 'react';
import api from '../config/api';
import { authService } from '../services/authService';

export const TokenDebugComponent: React.FC = () => {
    const [testResult, setTestResult] = useState<any>(null);
    const [loading, setLoading] = useState(false);

    // Quick test function to check basic connectivity
    const quickTest = async () => {
        console.log('🔧 Quick Token Test Started');

        // Check if token exists
        const token = localStorage.getItem('jwtToken') || sessionStorage.getItem('jwtToken');
        console.log('Token exists:', !!token);
        console.log('Token length:', token?.length || 0);

        if (token) {
            console.log('Token preview:', token.substring(0, 50) + '...');

            // Test manual API call
            try {
                const response = await fetch('/api/customers', {
                    method: 'GET',
                    headers: {
                        'Authorization': `Bearer ${token}`,
                        'Content-Type': 'application/json'
                    }
                });
                console.log('Manual API call status:', response.status);
                console.log('Manual API call ok:', response.ok);

                if (!response.ok) {
                    const errorText = await response.text();
                    console.log('Error response:', errorText);
                }
            } catch (error) {
                console.error('Manual API call failed:', error);
            }
        }
    };

    const testTokenFlow = async () => {
        setLoading(true);
        const results: any = {
            timestamp: new Date().toISOString(),
            tests: {}
        };

        try {
            // 1. Check storage
            const localToken = localStorage.getItem('jwtToken');
            const sessionToken = sessionStorage.getItem('jwtToken');
            const activeToken = localToken || sessionToken;

            results.tests.storage = {
                hasLocalToken: !!localToken,
                hasSessionToken: !!sessionToken,
                activeToken: activeToken ? activeToken.substring(0, 50) + '...' : null,
                tokenLength: activeToken?.length || 0
            };

            // 2. Test authService
            results.tests.authService = {
                isAuthenticated: authService.isAuthenticated(),
                getToken: !!authService.getToken(),
                getCurrentUser: authService.getCurrentUser(),
                getUserInfo: authService.getUserInfo()
            };

            // 3. Decode token if available
            if (activeToken) {
                try {
                    const base64Url = activeToken.split('.')[1];
                    const base64 = base64Url.replace(/-/g, '+').replace(/_/g, '/');
                    const jsonPayload = decodeURIComponent(
                        atob(base64)
                            .split('')
                            .map(c => '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2))
                            .join('')
                    );
                    const payload = JSON.parse(jsonPayload);

                    results.tests.tokenPayload = {
                        sub: payload.sub,
                        role: payload.role,
                        iat: new Date(payload.iat * 1000).toISOString(),
                        exp: new Date(payload.exp * 1000).toISOString(),
                        isExpired: payload.exp < Date.now() / 1000,
                        timeToExpiry: Math.round((payload.exp * 1000 - Date.now()) / 1000) + 's'
                    };
                } catch (error: any) {
                    results.tests.tokenPayload = { error: error?.message || 'Unknown error' };
                }
            }

            // 4. Test health endpoint (no auth required)
            try {
                const healthResponse = await fetch('/api/health');
                results.tests.healthEndpoint = {
                    status: healthResponse.status,
                    ok: healthResponse.ok,
                    data: await healthResponse.json()
                };
            } catch (error: any) {
                results.tests.healthEndpoint = { error: error?.message || 'Unknown error' };
            }

            // 5. Test customers endpoint with manual fetch
            if (activeToken) {
                try {
                    const manualResponse = await fetch('/api/customers', {
                        method: 'GET',
                        headers: {
                            'Authorization': `Bearer ${activeToken}`,
                            'Content-Type': 'application/json'
                        }
                    });

                    results.tests.manualApiCall = {
                        status: manualResponse.status,
                        ok: manualResponse.ok,
                        headers: Object.fromEntries(manualResponse.headers.entries()),
                        data: manualResponse.ok ? await manualResponse.json() : await manualResponse.text()
                    };
                } catch (error: any) {
                    results.tests.manualApiCall = { error: error?.message || 'Unknown error' };
                }

                // 6. Test with axios api instance
                try {
                    const axiosResponse = await api.get('/api/customers');
                    results.tests.axiosApiCall = {
                        status: axiosResponse.status,
                        data: axiosResponse.data
                    };
                } catch (error: any) {
                    results.tests.axiosApiCall = {
                        error: error.message,
                        status: error.response?.status,
                        data: error.response?.data
                    };
                }
            }

        } catch (error: any) {
            results.error = error.message;
        }

        setTestResult(results);
        setLoading(false);
    };

    return (
        <div style={{
            padding: '20px',
            backgroundColor: '#f5f5f5',
            border: '1px solid #ddd',
            borderRadius: '8px',
            margin: '20px'
        }}>
            <h3>🔧 Token Debug Panel</h3>
            <div style={{ marginBottom: '10px' }}>
                <button
                    onClick={quickTest}
                    style={{
                        padding: '8px 16px',
                        backgroundColor: '#28a745',
                        color: 'white',
                        border: 'none',
                        borderRadius: '4px',
                        cursor: 'pointer',
                        marginRight: '10px'
                    }}
                >
                    ⚡ Quick Test
                </button>
                <button
                    onClick={testTokenFlow}
                    disabled={loading}
                    style={{
                        padding: '10px 20px',
                        backgroundColor: '#007bff',
                        color: 'white',
                        border: 'none',
                        borderRadius: '4px',
                        cursor: loading ? 'not-allowed' : 'pointer'
                    }}
                >
                    {loading ? '🔄 Testing...' : '🧪 Full Token Tests'}
                </button>
            </div>

            {testResult && (
                <div style={{ marginTop: '20px' }}>
                    <h4>📊 Test Results:</h4>
                    <pre style={{
                        backgroundColor: '#fff',
                        padding: '15px',
                        borderRadius: '4px',
                        overflow: 'auto',
                        fontSize: '12px',
                        border: '1px solid #ddd'
                    }}>
                        {JSON.stringify(testResult, null, 2)}
                    </pre>
                </div>
            )}
        </div>
    );
};

export default TokenDebugComponent;
