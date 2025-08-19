import React, { useState } from 'react';
import { PhoneRegisterPage } from './PhoneRegisterPage';

interface User {
    phoneNumber: string;
    fullName: string;
    email?: string;
    registeredAt: string;
}

export const PhoneRegisterDemo: React.FC = () => {
    const [currentPage, setCurrentPage] = useState<'register' | 'success' | 'login'>('register');
    const [registeredUser, setRegisteredUser] = useState<User | null>(null);

    const handleRegisterSuccess = (userData: User) => {
        console.log('Registration successful:', userData);
        setRegisteredUser(userData);
        setCurrentPage('success');
    };

    const handleSwitchToLogin = () => {
        setCurrentPage('login');
    };

    const handleBackToRegister = () => {
        setCurrentPage('register');
        setRegisteredUser(null);
    };

    const handleGoToLogin = () => {
        setCurrentPage('login');
    };

    if (currentPage === 'success') {
        return (
            <div style={{
                minHeight: '100vh',
                display: 'flex',
                justifyContent: 'center',
                alignItems: 'center',
                background: 'linear-gradient(135deg, #28a745 0%, #20c997 100%)',
                padding: '20px',
                fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", "Roboto", sans-serif'
            }}>
                <div style={{
                    background: 'white',
                    borderRadius: '16px',
                    boxShadow: '0 20px 40px rgba(0, 0, 0, 0.1)',
                    padding: '40px',
                    textAlign: 'center',
                    maxWidth: '480px',
                    width: '100%'
                }}>
                    <div style={{
                        width: '80px',
                        height: '80px',
                        background: 'linear-gradient(135deg, #28a745 0%, #20c997 100%)',
                        borderRadius: '50%',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        margin: '0 auto 20px',
                        fontSize: '32px'
                    }}>
                        ✅
                    </div>

                    <h2 style={{ color: '#333', marginBottom: '16px' }}>
                        Đăng ký thành công!
                    </h2>

                    <p style={{ color: '#666', marginBottom: '24px', lineHeight: '1.5' }}>
                        Chào mừng <strong>{registeredUser?.fullName}</strong>!<br />
                        Tài khoản của bạn đã được tạo thành công với số điện thoại{' '}
                        <strong>{registeredUser?.phoneNumber}</strong>
                    </p>

                    {registeredUser?.email && (
                        <p style={{ color: '#666', marginBottom: '24px', fontSize: '14px' }}>
                            Email: {registeredUser.email}
                        </p>
                    )}

                    <div style={{ display: 'flex', gap: '12px', flexDirection: 'column' }}>
                        <button
                            onClick={handleGoToLogin}
                            style={{
                                background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
                                color: 'white',
                                border: 'none',
                                padding: '14px 24px',
                                borderRadius: '8px',
                                fontSize: '16px',
                                fontWeight: '600',
                                cursor: 'pointer',
                                transition: 'all 0.3s ease'
                            }}
                        >
                            Đăng nhập ngay
                        </button>

                        <button
                            onClick={handleBackToRegister}
                            style={{
                                background: 'none',
                                color: '#6c757d',
                                border: '2px solid #e1e5e9',
                                padding: '12px 24px',
                                borderRadius: '8px',
                                fontSize: '14px',
                                fontWeight: '500',
                                cursor: 'pointer'
                            }}
                        >
                            Đăng ký tài khoản khác
                        </button>
                    </div>
                </div>
            </div>
        );
    }

    if (currentPage === 'login') {
        return (
            <div style={{
                minHeight: '100vh',
                display: 'flex',
                justifyContent: 'center',
                alignItems: 'center',
                background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
                padding: '20px',
                fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", "Roboto", sans-serif'
            }}>
                <div style={{
                    background: 'white',
                    borderRadius: '16px',
                    boxShadow: '0 20px 40px rgba(0, 0, 0, 0.1)',
                    padding: '40px',
                    textAlign: 'center',
                    maxWidth: '480px',
                    width: '100%'
                }}>
                    <div style={{
                        width: '60px',
                        height: '60px',
                        background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
                        borderRadius: '12px',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        color: 'white',
                        fontWeight: 'bold',
                        fontSize: '18px',
                        margin: '0 auto 20px'
                    }}>
                        KLB
                    </div>

                    <h2 style={{ color: '#333', marginBottom: '16px' }}>
                        Trang đăng nhập
                    </h2>

                    <p style={{ color: '#666', marginBottom: '24px' }}>
                        Đây là nơi sẽ hiển thị form đăng nhập.<br />
                        Hiện tại đây chỉ là demo.
                    </p>

                    <button
                        onClick={handleBackToRegister}
                        style={{
                            background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
                            color: 'white',
                            border: 'none',
                            padding: '14px 24px',
                            borderRadius: '8px',
                            fontSize: '16px',
                            fontWeight: '600',
                            cursor: 'pointer'
                        }}
                    >
                        Quay lại đăng ký
                    </button>
                </div>
            </div>
        );
    }

    return (
        <PhoneRegisterPage
            onRegisterSuccess={handleRegisterSuccess}
            onSwitchToLogin={handleSwitchToLogin}
        />
    );
};

export default PhoneRegisterDemo;
