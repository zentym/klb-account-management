import React, { useState } from 'react';
import { authService } from '../services/authService';

interface RegisterData {
    phoneNumber: string;
    password: string;
    confirmPassword: string;
}

interface RegisterPageProps {
    onRegisterSuccess?: () => void;
    onSwitchToLogin?: () => void;
}

export const RegisterPage: React.FC<RegisterPageProps> = ({
    onRegisterSuccess,
    onSwitchToLogin
}) => {
    const [registerData, setRegisterData] = useState<RegisterData>({
        phoneNumber: '',
        password: '',
        confirmPassword: ''
    });
    const [loading, setLoading] = useState<boolean>(false);
    const [error, setError] = useState<string>('');
    const [success, setSuccess] = useState<string>('');

    const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
        const { name, value } = e.target;
        setRegisterData(prev => ({
            ...prev,
            [name]: value
        }));
        // Clear error when user starts typing
        if (error) setError('');
    };

    const validateForm = (): boolean => {
        if (!registerData.phoneNumber.trim()) {
            setError('Số điện thoại không được để trống');
            return false;
        }
        // Validate Vietnamese phone number format
        const phoneRegex = /^(\+84|0)[0-9]{9,10}$/;
        if (!phoneRegex.test(registerData.phoneNumber)) {
            setError('Số điện thoại không đúng định dạng (VD: 0901234567)');
            return false;
        }
        if (!registerData.password) {
            setError('Mật khẩu không được để trống');
            return false;
        }
        if (registerData.password.length < 6) {
            setError('Mật khẩu phải có ít nhất 6 ký tự');
            return false;
        }
        if (registerData.password !== registerData.confirmPassword) {
            setError('Mật khẩu không khớp');
            return false;
        }
        return true;
    };

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();

        if (!validateForm()) return;

        try {
            setLoading(true);
            setError('');
            setSuccess('');

            const response = await authService.register(
                registerData.phoneNumber,
                registerData.password
            );

            setSuccess('Đăng ký thành công! Bạn có thể đăng nhập ngay bây giờ.');
            setRegisterData({ phoneNumber: '', password: '', confirmPassword: '' });

            // Call success callback if provided
            if (onRegisterSuccess) {
                setTimeout(() => {
                    onRegisterSuccess();
                }, 2000);
            }

        } catch (err: any) {
            console.error('Registration error:', err);
            setError(err.message || 'Registration failed. Please try again.');
        } finally {
            setLoading(false);
        }
    };

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
                🏦 Create Account
            </h2>

            {error && (
                <div style={{
                    padding: '10px',
                    backgroundColor: '#ffebee',
                    color: '#c62828',
                    borderRadius: '4px',
                    marginBottom: '20px',
                    border: '1px solid #ffcdd2'
                }}>
                    {error}
                </div>
            )}

            {success && (
                <div style={{
                    padding: '10px',
                    backgroundColor: '#e8f5e8',
                    color: '#2e7d32',
                    borderRadius: '4px',
                    marginBottom: '20px',
                    border: '1px solid #c8e6c9'
                }}>
                    {success}
                </div>
            )}

            <form onSubmit={handleSubmit}>
                <div style={{ marginBottom: '20px' }}>
                    <label style={{
                        display: 'block',
                        marginBottom: '5px',
                        fontWeight: 'bold',
                        color: '#333'
                    }}>
                        📱 Số điện thoại:
                    </label>
                    <input
                        type="tel"
                        name="phoneNumber"
                        value={registerData.phoneNumber}
                        onChange={handleInputChange}
                        style={{
                            width: '100%',
                            padding: '10px',
                            border: '1px solid #ddd',
                            borderRadius: '4px',
                            fontSize: '16px',
                            boxSizing: 'border-box'
                        }}
                        placeholder="Nhập số điện thoại (VD: 0901234567)"
                        disabled={loading}
                        required
                    />
                </div>

                <div style={{ marginBottom: '20px' }}>
                    <label style={{
                        display: 'block',
                        marginBottom: '5px',
                        fontWeight: 'bold',
                        color: '#333'
                    }}>
                        🔒 Mật khẩu:
                    </label>
                    <input
                        type="password"
                        name="password"
                        value={registerData.password}
                        onChange={handleInputChange}
                        style={{
                            width: '100%',
                            padding: '10px',
                            border: '1px solid #ddd',
                            borderRadius: '4px',
                            fontSize: '16px',
                            boxSizing: 'border-box'
                        }}
                        placeholder="Nhập mật khẩu"
                        disabled={loading}
                        required
                    />
                </div>

                <div style={{ marginBottom: '20px' }}>
                    <label style={{
                        display: 'block',
                        marginBottom: '5px',
                        fontWeight: 'bold',
                        color: '#333'
                    }}>
                        🔒 Xác nhận mật khẩu:
                    </label>
                    <input
                        type="password"
                        name="confirmPassword"
                        value={registerData.confirmPassword}
                        onChange={handleInputChange}
                        style={{
                            width: '100%',
                            padding: '10px',
                            border: '1px solid #ddd',
                            borderRadius: '4px',
                            fontSize: '16px',
                            boxSizing: 'border-box'
                        }}
                        placeholder="Nhập lại mật khẩu"
                        disabled={loading}
                        required
                    />
                </div>

                <button
                    type="submit"
                    disabled={loading}
                    style={{
                        width: '100%',
                        padding: '12px',
                        backgroundColor: loading ? '#ccc' : '#1976d2',
                        color: 'white',
                        border: 'none',
                        borderRadius: '4px',
                        fontSize: '16px',
                        fontWeight: 'bold',
                        cursor: loading ? 'not-allowed' : 'pointer',
                        marginBottom: '15px'
                    }}
                >
                    {loading ? 'Creating Account...' : 'Create Account'}
                </button>

                {onSwitchToLogin && (
                    <div style={{ textAlign: 'center' }}>
                        <span style={{ color: '#666' }}>Already have an account? </span>
                        <button
                            type="button"
                            onClick={onSwitchToLogin}
                            style={{
                                background: 'none',
                                border: 'none',
                                color: '#1976d2',
                                textDecoration: 'underline',
                                cursor: 'pointer',
                                fontSize: '14px'
                            }}
                        >
                            Login here
                        </button>
                    </div>
                )}
            </form>
        </div>
    );
};

export default RegisterPage;
