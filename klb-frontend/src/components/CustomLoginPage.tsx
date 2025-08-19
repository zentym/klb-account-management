import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import customKeycloakService from '../services/customKeycloakService';

interface CustomLoginPageProps {
    onLoginSuccess?: (userInfo: any) => void;
    onSwitchToRegister?: () => void;
}

const CustomLoginPage: React.FC<CustomLoginPageProps> = ({
    onLoginSuccess,
    onSwitchToRegister
}) => {
    const [formData, setFormData] = useState({
        username: '',
        password: '',
        rememberMe: true
    });
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState<string | null>(null);
    const navigate = useNavigate();

    // Check if user is already logged in
    useEffect(() => {
        if (customKeycloakService.isAuthenticated()) {
            navigate('/dashboard', { replace: true });
        }
    }, [navigate]);

    const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
        const { name, value, type, checked } = e.target;
        setFormData(prev => ({
            ...prev,
            [name]: type === 'checkbox' ? checked : value
        }));
        // Clear error when user starts typing
        if (error) setError(null);
    };

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setLoading(true);
        setError(null);

        try {
            // Validate inputs
            if (!formData.username.trim() || !formData.password.trim()) {
                throw new Error('Vui lòng nhập đầy đủ tên đăng nhập và mật khẩu');
            }

            // Call custom login service
            const userInfo = await customKeycloakService.login(
                formData.username.trim(),
                formData.password
            );

            console.log('Login successful:', userInfo);

            // Call success callback if provided
            if (onLoginSuccess) {
                onLoginSuccess(userInfo);
            }

            // Navigate based on role
            const returnUrl = new URLSearchParams(window.location.search).get('returnUrl');
            if (returnUrl) {
                navigate(decodeURIComponent(returnUrl), { replace: true });
            } else if (userInfo.roles.includes('admin') || userInfo.roles.includes('ADMIN')) {
                navigate('/admin/dashboard', { replace: true });
            } else {
                navigate('/dashboard', { replace: true });
            }

        } catch (err) {
            console.error('Login failed:', err);
            setError(err instanceof Error ? err.message : 'Đăng nhập thất bại');
        } finally {
            setLoading(false);
        }
    };

    // Demo users info
    const demoUsers = [
        { username: '0901234567', password: 'admin123', role: 'Admin' },
        { username: '0987654321', password: 'password123', role: 'User' }
    ];

    return (
        <div style={styles.container}>
            <div style={styles.backgroundPattern}></div>

            <div style={styles.loginCard}>
                {/* Header */}
                <div style={styles.header}>
                    <div style={styles.logo}>
                        🏦
                    </div>
                    <h1 style={styles.title}>Kienlongbank</h1>
                    <p style={styles.subtitle}>Đăng nhập vào hệ thống quản lý tài khoản</p>
                </div>

                {/* Login Form */}
                <form onSubmit={handleSubmit} style={styles.form}>
                    {/* Phone Number Input */}
                    <div style={styles.inputGroup}>
                        <label style={styles.label} htmlFor="phoneNumber">
                            � Số điện thoại
                        </label>
                        <input
                            id="phoneNumber"
                            name="username"
                            type="tel"
                            value={formData.username}
                            onChange={handleInputChange}
                            style={{
                                ...styles.input,
                                ...(error ? styles.inputError : {})
                            }}
                            placeholder="Nhập số điện thoại (VD: 0901234567)"
                            disabled={loading}
                            autoComplete="tel"
                        />
                    </div>

                    {/* Password Input */}
                    <div style={styles.inputGroup}>
                        <label style={styles.label} htmlFor="password">
                            🔒 Mật khẩu
                        </label>
                        <input
                            id="password"
                            name="password"
                            type="password"
                            value={formData.password}
                            onChange={handleInputChange}
                            style={{
                                ...styles.input,
                                ...(error ? styles.inputError : {})
                            }}
                            placeholder="Nhập mật khẩu"
                            disabled={loading}
                            autoComplete="current-password"
                        />
                    </div>

                    {/* Remember Me */}
                    <div style={styles.checkboxGroup}>
                        <input
                            id="rememberMe"
                            name="rememberMe"
                            type="checkbox"
                            checked={formData.rememberMe}
                            onChange={handleInputChange}
                            style={styles.checkbox}
                            disabled={loading}
                        />
                        <label htmlFor="rememberMe" style={styles.checkboxLabel}>
                            Ghi nhớ đăng nhập
                        </label>
                    </div>

                    {/* Error Message */}
                    {error && (
                        <div style={styles.errorMessage}>
                            ⚠️ {error}
                        </div>
                    )}

                    {/* Login Button */}
                    <button
                        type="submit"
                        disabled={loading}
                        style={{
                            ...styles.loginButton,
                            ...(loading ? styles.loginButtonDisabled : {})
                        }}
                        onMouseEnter={(e) => {
                            if (!loading) {
                                e.currentTarget.style.backgroundColor = '#1565c0';
                            }
                        }}
                        onMouseLeave={(e) => {
                            if (!loading) {
                                e.currentTarget.style.backgroundColor = '#1976d2';
                            }
                        }}
                    >
                        {loading ? '🔄 Đang đăng nhập...' : '🚀 Đăng nhập'}
                    </button>
                </form>

                {/* Demo Users Info */}
                <div style={styles.demoSection}>
                    <h4 style={styles.demoTitle}>🧪 Tài khoản demo:</h4>
                    <div style={styles.demoUsers}>
                        {demoUsers.map((user, index) => (
                            <div key={index} style={styles.demoUser}>
                                <div style={styles.demoUserInfo}>
                                    <strong>{user.username}</strong> / {user.password}
                                    <span style={styles.demoUserRole}>({user.role})</span>
                                </div>
                                <button
                                    type="button"
                                    onClick={() => {
                                        setFormData(prev => ({
                                            ...prev,
                                            username: user.username,
                                            password: user.password
                                        }));
                                    }}
                                    style={styles.fillButton}
                                    disabled={loading}
                                >
                                    Điền
                                </button>
                            </div>
                        ))}
                    </div>
                </div>

                {/* Footer */}
                <div style={styles.footer}>
                    <p style={styles.footerText}>
                        🔒 Kết nối bảo mật với Keycloak
                    </p>
                    {onSwitchToRegister && (
                        <p>
                            <span style={styles.footerText}>Chưa có tài khoản? </span>
                            <button
                                onClick={onSwitchToRegister}
                                style={styles.linkButton}
                                disabled={loading}
                            >
                                Đăng ký ngay
                            </button>
                        </p>
                    )}
                </div>
            </div>
        </div>
    );
};

// Styles
const styles = {
    container: {
        minHeight: '100vh',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
        padding: '20px',
        position: 'relative' as const,
    },
    backgroundPattern: {
        position: 'absolute' as const,
        top: 0,
        left: 0,
        right: 0,
        bottom: 0,
        opacity: 0.1,
        backgroundImage: `url("data:image/svg+xml,%3Csvg width='60' height='60' viewBox='0 0 60 60' xmlns='http://www.w3.org/2000/svg'%3E%3Cg fill='none' fill-rule='evenodd'%3E%3Cg fill='%23ffffff' fill-opacity='0.1'%3E%3Ccircle cx='30' cy='30' r='4'/%3E%3C/g%3E%3C/g%3E%3C/svg%3E")`,
    },
    loginCard: {
        backgroundColor: 'white',
        borderRadius: '16px',
        padding: '40px',
        width: '100%',
        maxWidth: '480px',
        boxShadow: '0 20px 60px rgba(0, 0, 0, 0.15)',
        position: 'relative' as const,
        zIndex: 1,
    },
    header: {
        textAlign: 'center' as const,
        marginBottom: '30px',
    },
    logo: {
        fontSize: '48px',
        marginBottom: '16px',
    },
    title: {
        fontSize: '28px',
        fontWeight: 'bold',
        color: '#1976d2',
        margin: '0 0 8px 0',
    },
    subtitle: {
        color: '#666',
        fontSize: '16px',
        margin: 0,
    },
    form: {
        marginBottom: '30px',
    },
    inputGroup: {
        marginBottom: '20px',
    },
    label: {
        display: 'block',
        marginBottom: '8px',
        color: '#333',
        fontSize: '14px',
        fontWeight: '500',
    },
    input: {
        width: '100%',
        padding: '14px 16px',
        border: '2px solid #e0e0e0',
        borderRadius: '8px',
        fontSize: '16px',
        transition: 'border-color 0.3s ease',
        boxSizing: 'border-box' as const,
        outline: 'none',
    },
    inputError: {
        borderColor: '#f44336',
    },
    checkboxGroup: {
        display: 'flex',
        alignItems: 'center',
        marginBottom: '20px',
    },
    checkbox: {
        marginRight: '8px',
        transform: 'scale(1.1)',
    },
    checkboxLabel: {
        fontSize: '14px',
        color: '#666',
        cursor: 'pointer',
    },
    errorMessage: {
        backgroundColor: '#ffebee',
        color: '#c62828',
        padding: '12px 16px',
        borderRadius: '8px',
        fontSize: '14px',
        marginBottom: '20px',
        border: '1px solid #ffcdd2',
    },
    loginButton: {
        width: '100%',
        padding: '16px',
        backgroundColor: '#1976d2',
        color: 'white',
        border: 'none',
        borderRadius: '8px',
        fontSize: '16px',
        fontWeight: 'bold',
        cursor: 'pointer',
        transition: 'background-color 0.3s ease',
        outline: 'none',
    },
    loginButtonDisabled: {
        backgroundColor: '#bbb',
        cursor: 'not-allowed',
    },
    demoSection: {
        backgroundColor: '#f8f9fa',
        padding: '20px',
        borderRadius: '8px',
        marginBottom: '20px',
    },
    demoTitle: {
        margin: '0 0 12px 0',
        color: '#333',
        fontSize: '14px',
    },
    demoUsers: {
        display: 'flex',
        flexDirection: 'column' as const,
        gap: '8px',
    },
    demoUser: {
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center',
        padding: '8px 12px',
        backgroundColor: 'white',
        borderRadius: '6px',
        border: '1px solid #e0e0e0',
    },
    demoUserInfo: {
        fontSize: '14px',
        color: '#333',
    },
    demoUserRole: {
        color: '#666',
        fontSize: '12px',
        marginLeft: '8px',
    },
    fillButton: {
        padding: '4px 12px',
        backgroundColor: '#4caf50',
        color: 'white',
        border: 'none',
        borderRadius: '4px',
        fontSize: '12px',
        cursor: 'pointer',
        transition: 'background-color 0.3s ease',
    },
    footer: {
        textAlign: 'center' as const,
        padding: '20px 0 0 0',
        borderTop: '1px solid #f0f0f0',
    },
    footerText: {
        color: '#666',
        fontSize: '14px',
        margin: '0 0 8px 0',
    },
    linkButton: {
        background: 'none',
        border: 'none',
        color: '#1976d2',
        cursor: 'pointer',
        textDecoration: 'underline',
        fontSize: '14px',
    },
};

export default CustomLoginPage;
