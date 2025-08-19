import React, { useState } from 'react';
import { PhoneRegisterPage } from './PhoneRegisterPage';
import { PhoneLoginPage } from './PhoneLoginPage';
import './AuthFlow.css';

interface User {
    phoneNumber: string;
    fullName?: string;
    email?: string;
    registeredAt?: string;
    loginAt?: string;
    rememberMe?: boolean;
    otpVerified?: boolean;
}

interface AuthFlowProps {
    onAuthSuccess?: (user: User, type: 'login' | 'register') => void;
}

export const AuthFlow: React.FC<AuthFlowProps> = ({ onAuthSuccess }) => {
    const [currentView, setCurrentView] = useState<'login' | 'register' | 'forgot-password' | 'success'>('login');
    const [authenticatedUser, setAuthenticatedUser] = useState<User | null>(null);
    const [authType, setAuthType] = useState<'login' | 'register'>('login');

    const handleLoginSuccess = (userData: User) => {
        console.log('Login successful:', userData);
        setAuthenticatedUser(userData);
        setAuthType('login');
        setCurrentView('success');
    };

    const handleRegisterSuccess = (userData: User) => {
        console.log('Registration successful:', userData);
        setAuthenticatedUser(userData);
        setAuthType('register');
        setCurrentView('success');
    };

    const handleSwitchToRegister = () => {
        setCurrentView('register');
    };

    const handleSwitchToLogin = () => {
        setCurrentView('login');
    };

    const handleForgotPassword = () => {
        setCurrentView('forgot-password');
    };

    const handleContinueAfterSuccess = () => {
        if (onAuthSuccess && authenticatedUser) {
            onAuthSuccess(authenticatedUser, authType);
        }
    };

    const handleStartOver = () => {
        setCurrentView('login');
        setAuthenticatedUser(null);
    };

    if (currentView === 'success') {
        return (
            <div className="auth-success-container">
                <div className="auth-success-card">
                    <div className="success-animation">
                        <div className="success-circle">
                            <div className="success-checkmark">✓</div>
                        </div>
                    </div>

                    <h2 className="success-title">
                        {authType === 'login' ? 'Đăng nhập thành công!' : 'Đăng ký thành công!'}
                    </h2>

                    <div className="user-info">
                        <div className="user-avatar">
                            👤
                        </div>
                        <div className="user-details">
                            {authenticatedUser?.fullName && (
                                <div className="user-name">{authenticatedUser.fullName}</div>
                            )}
                            <div className="user-phone">{authenticatedUser?.phoneNumber}</div>
                            {authenticatedUser?.email && (
                                <div className="user-email">{authenticatedUser.email}</div>
                            )}
                        </div>
                    </div>

                    <div className="success-info">
                        {authType === 'login' ? (
                            <p>
                                Chào mừng bạn trở lại! Bạn đã đăng nhập thành công vào hệ thống Kienlongbank.
                                {authenticatedUser?.otpVerified && <span className="security-note"> 🔐 Đã xác thực OTP</span>}
                            </p>
                        ) : (
                            <p>
                                Tài khoản của bạn đã được tạo thành công! Bạn có thể bắt đầu sử dụng các dịch vụ của Kienlongbank.
                            </p>
                        )}
                    </div>

                    <div className="success-actions">
                        <button
                            onClick={handleContinueAfterSuccess}
                            className="primary-action-btn"
                        >
                            {authType === 'login' ? 'Vào Dashboard' : 'Bắt đầu sử dụng'}
                        </button>

                        <button
                            onClick={handleStartOver}
                            className="secondary-action-btn"
                        >
                            {authType === 'login' ? 'Đăng nhập tài khoản khác' : 'Tạo tài khoản khác'}
                        </button>
                    </div>

                    <div className="auth-timestamp">
                        <small>
                            {authType === 'login'
                                ? `Thời gian đăng nhập: ${new Date(authenticatedUser?.loginAt || '').toLocaleString('vi-VN')}`
                                : `Thời gian đăng ký: ${new Date(authenticatedUser?.registeredAt || '').toLocaleString('vi-VN')}`
                            }
                        </small>
                    </div>
                </div>
            </div>
        );
    }

    if (currentView === 'forgot-password') {
        return (
            <div className="forgot-password-container">
                <div className="forgot-password-card">
                    <div className="forgot-password-header">
                        <div className="logo-section">
                            <div className="logo-placeholder">KLB</div>
                            <h1>Kienlongbank</h1>
                        </div>
                        <h2>Quên mật khẩu</h2>
                        <p>Nhập số điện thoại để nhận mã khôi phục</p>
                    </div>

                    <div className="coming-soon-message">
                        <div className="coming-soon-icon">🚧</div>
                        <h3>Tính năng đang phát triển</h3>
                        <p>Chức năng khôi phục mật khẩu sẽ sớm được ra mắt. Vui lòng liên hệ hotline để được hỗ trợ.</p>

                        <div className="contact-info">
                            <div className="contact-item">
                                <span className="contact-icon">📞</span>
                                <span>Hotline: 1900-XXX-XXX</span>
                            </div>
                            <div className="contact-item">
                                <span className="contact-icon">📧</span>
                                <span>Email: support@kienlongbank.com</span>
                            </div>
                        </div>
                    </div>

                    <button
                        onClick={handleSwitchToLogin}
                        className="back-to-login-btn"
                    >
                        Quay lại đăng nhập
                    </button>
                </div>
            </div>
        );
    }

    if (currentView === 'register') {
        return (
            <PhoneRegisterPage
                onRegisterSuccess={handleRegisterSuccess}
                onSwitchToLogin={handleSwitchToLogin}
            />
        );
    }

    // Default: Login view
    return (
        <PhoneLoginPage
            onLoginSuccess={handleLoginSuccess}
            onSwitchToRegister={handleSwitchToRegister}
            onForgotPassword={handleForgotPassword}
        />
    );
};

export default AuthFlow;
