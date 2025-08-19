import React, { useState } from 'react';
import './PhoneLoginPage.css';
import customKeycloakService from '../services/customKeycloakService';

interface LoginFormData {
    phoneNumber: string;
    password: string;
    rememberMe: boolean;
}

interface VerificationData {
    otpCode: string;
}

interface PhoneLoginPageProps {
    onLoginSuccess?: (userData: any) => void;
    onSwitchToRegister?: () => void;
    onForgotPassword?: () => void;
}

export const PhoneLoginPage: React.FC<PhoneLoginPageProps> = ({
    onLoginSuccess,
    onSwitchToRegister,
    onForgotPassword
}) => {
    // Step management
    const [currentStep, setCurrentStep] = useState<'login' | 'verify'>('login');

    // Form data
    const [formData, setFormData] = useState<LoginFormData>({
        phoneNumber: '',
        password: '',
        rememberMe: false
    });

    const [verificationData, setVerificationData] = useState<VerificationData>({
        otpCode: ''
    });

    // UI states
    const [loading, setLoading] = useState<boolean>(false);
    const [error, setError] = useState<string>('');
    const [success, setSuccess] = useState<string>('');
    const [showPassword, setShowPassword] = useState<boolean>(false);
    const [otpTimer, setOtpTimer] = useState<number>(0);
    const [requireOtp, setRequireOtp] = useState<boolean>(false);

    // Handle input changes for login form
    const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
        const { name, value, type, checked } = e.target;
        setFormData(prev => ({
            ...prev,
            [name]: type === 'checkbox' ? checked : value
        }));

        // Clear error when user starts typing
        if (error) setError('');
    };

    // Handle OTP input change
    const handleOtpChange = (e: React.ChangeEvent<HTMLInputElement>) => {
        const { value } = e.target;
        // Only allow numbers and limit to 6 digits
        if (/^\d{0,6}$/.test(value)) {
            setVerificationData({ otpCode: value });
        }
        if (error) setError('');
    };

    // Format phone number display
    const formatPhoneNumber = (phone: string): string => {
        if (phone.startsWith('+84')) {
            return phone.replace('+84', '0');
        }
        return phone;
    };

    // Validate login form
    const validateLoginForm = (): boolean => {
        if (!formData.phoneNumber.trim()) {
            setError('Vui lòng nhập số điện thoại');
            return false;
        }

        // Validate Vietnamese phone number format
        const phoneRegex = /^(\+84|0)(3[2-9]|5[6|8|9]|7[0|6-9]|8[1-6|8|9]|9[0-9])[0-9]{7}$/;
        const cleanPhone = formData.phoneNumber.replace(/\s/g, '');
        if (!phoneRegex.test(cleanPhone)) {
            setError('Số điện thoại không đúng định dạng');
            return false;
        }

        if (!formData.password) {
            setError('Vui lòng nhập mật khẩu');
            return false;
        }

        return true;
    };

    // Handle login form submission
    const handleLoginSubmit = async (e: React.FormEvent) => {
        e.preventDefault();

        if (!validateLoginForm()) {
            return;
        }

        setLoading(true);
        setError('');
        setSuccess('');

        try {
            // Call Keycloak for authentication
            console.log('🔐 Authenticating with Keycloak...');
            const userInfo = await customKeycloakService.login(formData.phoneNumber, formData.password);
            console.log('✅ Keycloak login successful:', userInfo);

            // Direct login success with Keycloak
            const userData = {
                phoneNumber: formData.phoneNumber,
                fullName: userInfo.name || formData.phoneNumber,
                email: userInfo.email || '',
                username: userInfo.username,
                token: userInfo.token,
                roles: userInfo.roles,
                loginAt: new Date().toISOString(),
                rememberMe: formData.rememberMe
            };

            setSuccess('Đăng nhập thành công!');

            setTimeout(() => {
                if (onLoginSuccess) {
                    onLoginSuccess(userData);
                }
            }, 1500);

        } catch (keycloakError: any) {
            console.error('❌ Keycloak login failed:', keycloakError);

            // If Keycloak fails, fall back to OTP flow for demo
            if (keycloakError.message?.includes('Tên đăng nhập hoặc mật khẩu không đúng')) {
                setError('Số điện thoại hoặc mật khẩu không đúng');
            } else {
                // Fallback to OTP for demo purposes
                console.log('🔄 Falling back to OTP verification...');
                setRequireOtp(true);
                setSuccess('Vì lý do bảo mật, vui lòng xác thực bằng OTP');
                setCurrentStep('verify');
                startOtpTimer();
            }
        } finally {
            setLoading(false);
        }
    };

    // Handle OTP verification
    const handleVerifyOtp = async (e: React.FormEvent) => {
        e.preventDefault();

        if (!verificationData.otpCode) {
            setError('Vui lòng nhập mã OTP');
            return;
        }

        if (verificationData.otpCode.length !== 6) {
            setError('Mã OTP phải có 6 chữ số');
            return;
        }

        setLoading(true);
        setError('');

        try {
            // Simulate API call for OTP verification
            await simulateApiCall(1500);

            const userData = {
                phoneNumber: formData.phoneNumber,
                loginAt: new Date().toISOString(),
                rememberMe: formData.rememberMe,
                otpVerified: true
            };

            setSuccess('Đăng nhập thành công!');

            setTimeout(() => {
                if (onLoginSuccess) {
                    onLoginSuccess(userData);
                }
            }, 1500);
        } catch (err) {
            setError('Mã OTP không chính xác hoặc đã hết hạn');
        } finally {
            setLoading(false);
        }
    };

    // Start OTP timer
    const startOtpTimer = () => {
        setOtpTimer(120); // 2 minutes
        const timer = setInterval(() => {
            setOtpTimer(prev => {
                if (prev <= 1) {
                    clearInterval(timer);
                    return 0;
                }
                return prev - 1;
            });
        }, 1000);
    };

    // Resend OTP
    const handleResendOtp = async () => {
        setLoading(true);
        setError('');

        try {
            await simulateApiCall(1000);
            setSuccess('Mã OTP mới đã được gửi');
            startOtpTimer();
        } catch (err) {
            setError('Có lỗi khi gửi lại mã OTP');
        } finally {
            setLoading(false);
        }
    };

    // Go back to login form
    const handleBackToLogin = () => {
        setCurrentStep('login');
        setVerificationData({ otpCode: '' });
        setError('');
        setSuccess('');
        setOtpTimer(0);
        setRequireOtp(false);
    };

    // Simulate API call
    const simulateApiCall = (delay: number): Promise<void> => {
        return new Promise((resolve, reject) => {
            setTimeout(() => {
                // Simulate 85% success rate
                if (Math.random() > 0.15) {
                    resolve();
                } else {
                    reject(new Error('Simulated API error'));
                }
            }, delay);
        });
    };

    // Format timer display
    const formatTimer = (seconds: number): string => {
        const mins = Math.floor(seconds / 60);
        const secs = seconds % 60;
        return `${mins}:${secs.toString().padStart(2, '0')}`;
    };

    return (
        <div className="phone-login-container">
            <div className="phone-login-card">
                {/* Header */}
                <div className="login-header">
                    <div className="logo-section">
                        <div className="logo-placeholder">KLB</div>
                        <h1>Kienlongbank</h1>
                    </div>
                    <h2>
                        {currentStep === 'login' ? 'Đăng nhập' : 'Xác thực đăng nhập'}
                    </h2>
                    <p className="login-subtitle">
                        {currentStep === 'login'
                            ? 'Đăng nhập bằng số điện thoại và mật khẩu'
                            : `Nhập mã OTP được gửi đến ${formatPhoneNumber(formData.phoneNumber)}`
                        }
                    </p>
                </div>

                {/* Messages */}
                {error && (
                    <div className="error-message">
                        <span className="error-icon">⚠️</span>
                        {error}
                    </div>
                )}

                {success && (
                    <div className="success-message">
                        <span className="success-icon">✅</span>
                        {success}
                    </div>
                )}

                {/* Login Form */}
                {currentStep === 'login' && (
                    <form onSubmit={handleLoginSubmit} className="login-form">
                        <div className="form-group">
                            <label htmlFor="phoneNumber" className="form-label">
                                Số điện thoại <span className="required">*</span>
                            </label>
                            <input
                                type="tel"
                                id="phoneNumber"
                                name="phoneNumber"
                                value={formData.phoneNumber}
                                onChange={handleInputChange}
                                placeholder="Nhập số điện thoại (VD: 0901234567)"
                                className="form-input"
                                disabled={loading}
                                autoComplete="tel"
                            />
                        </div>

                        <div className="form-group">
                            <label htmlFor="password" className="form-label">
                                Mật khẩu <span className="required">*</span>
                            </label>
                            <div className="password-input-container">
                                <input
                                    type={showPassword ? "text" : "password"}
                                    id="password"
                                    name="password"
                                    value={formData.password}
                                    onChange={handleInputChange}
                                    placeholder="Nhập mật khẩu"
                                    className="form-input"
                                    disabled={loading}
                                    autoComplete="current-password"
                                />
                                <button
                                    type="button"
                                    className="password-toggle"
                                    onClick={() => setShowPassword(!showPassword)}
                                    disabled={loading}
                                >
                                    {showPassword ? "🙈" : "👁️"}
                                </button>
                            </div>
                        </div>

                        <div className="form-options">
                            <label className="checkbox-label">
                                <input
                                    type="checkbox"
                                    name="rememberMe"
                                    checked={formData.rememberMe}
                                    onChange={handleInputChange}
                                    disabled={loading}
                                    className="checkbox-input"
                                />
                                <span className="checkmark"></span>
                                Ghi nhớ đăng nhập
                            </label>

                            <button
                                type="button"
                                onClick={onForgotPassword}
                                className="forgot-password-link"
                                disabled={loading}
                            >
                                Quên mật khẩu?
                            </button>
                        </div>

                        <button
                            type="submit"
                            className="login-button"
                            disabled={loading}
                        >
                            {loading ? (
                                <span className="loading-spinner">⏳ Đang đăng nhập...</span>
                            ) : (
                                'Đăng nhập'
                            )}
                        </button>
                    </form>
                )}

                {/* OTP Verification Form */}
                {currentStep === 'verify' && (
                    <form onSubmit={handleVerifyOtp} className="verify-form">
                        <div className="otp-info">
                            <div className="phone-display">
                                📱 {formatPhoneNumber(formData.phoneNumber)}
                            </div>
                            <p>Vui lòng nhập mã OTP gồm 6 chữ số</p>
                        </div>

                        <div className="form-group otp-group">
                            <label htmlFor="otpCode" className="form-label">
                                Mã OTP <span className="required">*</span>
                            </label>
                            <input
                                type="text"
                                id="otpCode"
                                name="otpCode"
                                value={verificationData.otpCode}
                                onChange={handleOtpChange}
                                placeholder="Nhập 6 chữ số"
                                className="otp-input"
                                maxLength={6}
                                disabled={loading}
                                autoComplete="one-time-code"
                            />
                        </div>

                        <div className="otp-actions">
                            {otpTimer > 0 ? (
                                <div className="timer-display">
                                    Gửi lại mã sau: {formatTimer(otpTimer)}
                                </div>
                            ) : (
                                <button
                                    type="button"
                                    onClick={handleResendOtp}
                                    className="resend-button"
                                    disabled={loading}
                                >
                                    Gửi lại mã OTP
                                </button>
                            )}
                        </div>

                        <div className="verify-buttons">
                            <button
                                type="button"
                                onClick={handleBackToLogin}
                                className="back-button"
                                disabled={loading}
                            >
                                Quay lại
                            </button>
                            <button
                                type="submit"
                                className="verify-button"
                                disabled={loading || verificationData.otpCode.length !== 6}
                            >
                                {loading ? (
                                    <span className="loading-spinner">⏳ Đang xác thực...</span>
                                ) : (
                                    'Xác thực'
                                )}
                            </button>
                        </div>
                    </form>
                )}

                {/* Footer */}
                <div className="login-footer">
                    <p>
                        Chưa có tài khoản?{' '}
                        <button
                            type="button"
                            onClick={onSwitchToRegister}
                            className="switch-button"
                            disabled={loading}
                        >
                            Đăng ký ngay
                        </button>
                    </p>
                </div>

                {/* Quick Login Options */}
                <div className="quick-login-section">
                    <div className="divider">
                        <span>Hoặc</span>
                    </div>

                    <div className="quick-login-buttons">
                        <button type="button" className="quick-login-btn biometric-btn" disabled={loading}>
                            👆 Vân tay
                        </button>
                        <button type="button" className="quick-login-btn face-id-btn" disabled={loading}>
                            👤 Face ID
                        </button>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default PhoneLoginPage;
