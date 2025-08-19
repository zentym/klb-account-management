import React, { useState, useEffect } from 'react';
import customKeycloakService from '../services/customKeycloakService';

const CustomLoginDemo: React.FC = () => {
    const [user, setUser] = useState<any>(null);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState<string>('');
    const [formData, setFormData] = useState({
        username: 'testuser',
        password: 'password123'
    });

    // Check if already logged in
    useEffect(() => {
        const currentUser = customKeycloakService.getCurrentUser();
        if (currentUser) {
            setUser(currentUser);
        }
    }, []);

    const handleLogin = async (e: React.FormEvent) => {
        e.preventDefault();
        setLoading(true);
        setError('');

        try {
            const userInfo = await customKeycloakService.login(formData.username, formData.password);
            setUser(userInfo);
            console.log('Login successful:', userInfo);
        } catch (err) {
            setError(err instanceof Error ? err.message : 'Login failed');
            console.error('Login failed:', err);
        } finally {
            setLoading(false);
        }
    };

    const handleLogout = async () => {
        setLoading(true);
        try {
            await customKeycloakService.logout();
            setUser(null);
            setError('');
            console.log('Logout successful');
        } catch (err) {
            console.error('Logout failed:', err);
        } finally {
            setLoading(false);
        }
    };

    const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
        setFormData(prev => ({
            ...prev,
            [e.target.name]: e.target.value
        }));
        if (error) setError('');
    };

    if (user) {
        return (
            <div style={styles.container}>
                <div style={styles.successCard}>
                    <h2 style={styles.title}>🎉 Đăng nhập thành công!</h2>

                    <div style={styles.userInfo}>
                        <h3>👤 Thông tin người dùng:</h3>
                        <div style={styles.infoGrid}>
                            <div><strong>Tên đăng nhập:</strong> {user.username}</div>
                            <div><strong>Email:</strong> {user.email || 'N/A'}</div>
                            <div><strong>Họ tên:</strong> {user.name || 'N/A'}</div>
                            <div><strong>Vai trò:</strong> {user.roles.join(', ')}</div>
                        </div>
                    </div>

                    <div style={styles.tokenInfo}>
                        <h3>🔐 Token Info:</h3>
                        <div><strong>Token:</strong> {user.token.substring(0, 50)}...</div>
                        <div><strong>Refresh Token:</strong> {user.refreshToken.substring(0, 30)}...</div>
                    </div>

                    <div style={styles.permissions}>
                        <h3>🛡️ Quyền hạn:</h3>
                        <div>
                            <span style={customKeycloakService.isAdmin() ? styles.hasPermission : styles.noPermission}>
                                {customKeycloakService.isAdmin() ? '✅' : '❌'} Admin Access
                            </span>
                        </div>
                        <div>
                            <span style={customKeycloakService.hasRole('USER') ? styles.hasPermission : styles.noPermission}>
                                {customKeycloakService.hasRole('USER') ? '✅' : '❌'} User Access
                            </span>
                        </div>
                    </div>

                    <div style={styles.actions}>
                        <button
                            onClick={handleLogout}
                            disabled={loading}
                            style={{ ...styles.button, ...styles.logoutButton }}
                        >
                            {loading ? '🔄 Đang đăng xuất...' : '🚪 Đăng xuất'}
                        </button>
                    </div>
                </div>
            </div>
        );
    }

    return (
        <div style={styles.container}>
            <div style={styles.loginCard}>
                <h2 style={styles.title}>🔐 Custom Keycloak Login Demo</h2>
                <p style={styles.subtitle}>Test trang đăng nhập tùy chỉnh với Keycloak API</p>

                <form onSubmit={handleLogin} style={styles.form}>
                    <div style={styles.inputGroup}>
                        <label style={styles.label}>� Số điện thoại:</label>
                        <input
                            name="username"
                            type="tel"
                            value={formData.username}
                            onChange={handleInputChange}
                            style={styles.input}
                            placeholder="Nhập số điện thoại (VD: 0901234567)"
                            disabled={loading}
                        />
                    </div>

                    <div style={styles.inputGroup}>
                        <label style={styles.label}>🔒 Mật khẩu:</label>
                        <input
                            name="password"
                            type="password"
                            value={formData.password}
                            onChange={handleInputChange}
                            style={styles.input}
                            disabled={loading}
                        />
                    </div>

                    {error && (
                        <div style={styles.error}>
                            ⚠️ {error}
                        </div>
                    )}

                    <button
                        type="submit"
                        disabled={loading}
                        style={{ ...styles.button, ...styles.loginButton }}
                    >
                        {loading ? '🔄 Đang đăng nhập...' : '🚀 Đăng nhập'}
                    </button>
                </form>

                <div style={styles.demoUsers}>
                    <h4>🧪 Tài khoản demo:</h4>
                    <div style={styles.userButtons}>
                        <button
                            type="button"
                            onClick={() => setFormData({ username: '0987654321', password: 'password123' })}
                            style={styles.demoButton}
                        >
                            0987654321 (USER)
                        </button>
                        <button
                            type="button"
                            onClick={() => setFormData({ username: '0901234567', password: 'admin123' })}
                            style={styles.demoButton}
                        >
                            0901234567 (ADMIN) - nếu có
                        </button>
                    </div>
                </div>
            </div>
        </div>
    );
};

const styles = {
    container: {
        minHeight: '100vh',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
        padding: '20px',
    },
    loginCard: {
        backgroundColor: 'white',
        borderRadius: '12px',
        padding: '30px',
        maxWidth: '400px',
        width: '100%',
        boxShadow: '0 10px 30px rgba(0,0,0,0.2)',
    },
    successCard: {
        backgroundColor: 'white',
        borderRadius: '12px',
        padding: '30px',
        maxWidth: '600px',
        width: '100%',
        boxShadow: '0 10px 30px rgba(0,0,0,0.2)',
    },
    title: {
        textAlign: 'center' as const,
        color: '#333',
        marginBottom: '10px',
    },
    subtitle: {
        textAlign: 'center' as const,
        color: '#666',
        marginBottom: '30px',
        fontSize: '14px',
    },
    form: {
        marginBottom: '20px',
    },
    inputGroup: {
        marginBottom: '15px',
    },
    label: {
        display: 'block',
        marginBottom: '5px',
        color: '#333',
        fontSize: '14px',
    },
    input: {
        width: '100%',
        padding: '10px',
        border: '1px solid #ddd',
        borderRadius: '6px',
        fontSize: '14px',
        boxSizing: 'border-box' as const,
    },
    button: {
        padding: '12px 20px',
        border: 'none',
        borderRadius: '6px',
        fontSize: '14px',
        cursor: 'pointer',
        transition: 'background-color 0.3s',
    },
    loginButton: {
        width: '100%',
        backgroundColor: '#4CAF50',
        color: 'white',
    },
    logoutButton: {
        backgroundColor: '#f44336',
        color: 'white',
    },
    error: {
        backgroundColor: '#ffebee',
        color: '#c62828',
        padding: '10px',
        borderRadius: '6px',
        marginBottom: '15px',
        fontSize: '14px',
    },
    demoUsers: {
        backgroundColor: '#f5f5f5',
        padding: '15px',
        borderRadius: '6px',
        marginTop: '20px',
    },
    userButtons: {
        display: 'flex',
        gap: '10px',
        flexDirection: 'column' as const,
    },
    demoButton: {
        padding: '8px 12px',
        backgroundColor: '#2196F3',
        color: 'white',
        border: 'none',
        borderRadius: '4px',
        cursor: 'pointer',
        fontSize: '12px',
    },
    userInfo: {
        marginBottom: '20px',
        padding: '15px',
        backgroundColor: '#e8f5e8',
        borderRadius: '6px',
    },
    infoGrid: {
        display: 'grid',
        gap: '8px',
    },
    tokenInfo: {
        marginBottom: '20px',
        padding: '15px',
        backgroundColor: '#e3f2fd',
        borderRadius: '6px',
        fontSize: '12px',
    },
    permissions: {
        marginBottom: '20px',
        padding: '15px',
        backgroundColor: '#fff3e0',
        borderRadius: '6px',
    },
    hasPermission: {
        color: '#4CAF50',
        fontWeight: 'bold',
    },
    noPermission: {
        color: '#f44336',
    },
    actions: {
        textAlign: 'center' as const,
    },
};

export default CustomLoginDemo;
