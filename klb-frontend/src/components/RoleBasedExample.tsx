import React from 'react';
import useCustomAuth from '../hooks/useCustomAuth';
import { authService } from '../services/authService';

/**
 * Example component demonstrating role-based access control
 */
export const RoleBasedExample: React.FC = () => {
    const { isAuthenticated, userInfo, hasRole } = useCustomAuth();
    const isAdmin = () => hasRole('ADMIN');

    // Example: Direct service usage
    const handleTestRoles = () => {
        console.log('=== Role Testing ===');
        console.log('Current user info:', authService.getUserInfo());
        console.log('Current user role:', authService.getUserRole());
        console.log('Is user admin?', authService.isAdmin());
        console.log('Has ADMIN role?', authService.hasRole('ADMIN'));
        console.log('Has USER role?', authService.hasRole('USER'));
        console.log('Has MANAGER role?', authService.hasRole('MANAGER'));
    };

    if (!isAuthenticated) {
        return (
            <div style={{ padding: '20px', border: '1px solid #ddd', margin: '20px' }}>
                <h3>🔒 Role-Based Access Control Demo</h3>
                <p>Please log in to see role-based content.</p>
            </div>
        );
    }

    return (
        <div style={{ padding: '20px', border: '1px solid #ddd', margin: '20px' }}>
            <h3>🎭 Role-Based Access Control Demo</h3>

            <div style={{ marginBottom: '20px' }}>
                <h4>Current User Information:</h4>
                <p><strong>Username:</strong> {userInfo?.username || 'N/A'}</p>
                <p><strong>Role:</strong> {userInfo?.roles?.join(', ') || 'N/A'}</p>
                <p><strong>Is Admin:</strong> {isAdmin() ? 'Yes' : 'No'}</p>
            </div>

            <div style={{ marginBottom: '20px' }}>
                <button
                    onClick={handleTestRoles}
                    style={{
                        padding: '10px 20px',
                        backgroundColor: '#1976d2',
                        color: 'white',
                        border: 'none',
                        borderRadius: '4px',
                        cursor: 'pointer'
                    }}
                >
                    Test Role Functions (Check Console)
                </button>
            </div>

            {/* Example: Content based on roles */}
            <div style={{ marginBottom: '20px' }}>
                <h4>Role-Based Content:</h4>

                {/* Content for all authenticated users */}
                <div style={{
                    padding: '10px',
                    backgroundColor: '#e3f2fd',
                    marginBottom: '10px',
                    borderRadius: '4px'
                }}>
                    <p>✅ <strong>All Users:</strong> This content is visible to all authenticated users.</p>
                </div>

                {/* Content only for admins */}
                {isAdmin() && (
                    <div style={{
                        padding: '10px',
                        backgroundColor: '#fff3e0',
                        marginBottom: '10px',
                        borderRadius: '4px'
                    }}>
                        <p>👑 <strong>Admin Only:</strong> This content is only visible to administrators.</p>
                        <p>🛠️ Admin tools and settings would go here.</p>
                    </div>
                )}

                {/* Content for specific roles */}
                {hasRole('USER') && (
                    <div style={{
                        padding: '10px',
                        backgroundColor: '#f3e5f5',
                        marginBottom: '10px',
                        borderRadius: '4px'
                    }}>
                        <p>👤 <strong>User Role:</strong> Standard user features and content.</p>
                    </div>
                )}

                {hasRole('MANAGER') && (
                    <div style={{
                        padding: '10px',
                        backgroundColor: '#e8f5e8',
                        marginBottom: '10px',
                        borderRadius: '4px'
                    }}>
                        <p>📊 <strong>Manager Role:</strong> Management dashboard and reports.</p>
                    </div>
                )}

                {/* Show message if user doesn't have admin or manager role */}
                {!isAdmin() && !hasRole('MANAGER') && (
                    <div style={{
                        padding: '10px',
                        backgroundColor: '#ffebee',
                        marginBottom: '10px',
                        borderRadius: '4px'
                    }}>
                        <p>⚠️ <strong>Limited Access:</strong> You don't have admin or manager privileges.</p>
                    </div>
                )}
            </div>

            <div style={{ fontSize: '12px', color: '#666' }}>
                <p><strong>How to use in your components:</strong></p>
                <ul>
                    <li>Use <code>useKeycloakAuth()</code> hook to access user info and role functions</li>
                    <li>Use <code>authService.getUserInfo()</code> to get user object</li>
                    <li>Use <code>authService.hasRole('ROLE_NAME')</code> to check specific roles</li>
                    <li>Use <code>authService.isAdmin()</code> for admin checks</li>
                </ul>
            </div>
        </div>
    );
};

export default RoleBasedExample;
