import React, { useState } from 'react';
import './PhoneRegisterPage.css';
import customKeycloakService from '../services/customKeycloakService';
import otpService from '../services/otpService';

interface RegisterFormData {
    phoneNumber: string;
    password: string;
    confirmPassword: string;
    fullName: string;
    email?: string;
    agreeToTerms: boolean;
}

interface VerificationData {
    otpCode: string;
}

interface PhoneRegisterPageProps {
    onRegisterSuccess?: (userData: any) => void;
    onSwitchToLogin?: () => void;
}

export const PhoneRegisterPage: React.FC<PhoneRegisterPageProps> = ({
    onRegisterSuccess,
    onSwitchToLogin
}) => {
    // Step management
    const [currentStep, setCurrentStep] = useState<'register' | 'verify'>('register');

    // Form data
    const [formData, setFormData] = useState<RegisterFormData>({
        phoneNumber: '',
        password: '',
        confirmPassword: '',
        fullName: '',
        email: '',
        agreeToTerms: false
    });

    const [verificationData, setVerificationData] = useState<VerificationData>({
        otpCode: ''
    });

    // UI states
    const [loading, setLoading] = useState<boolean>(false);
    const [error, setError] = useState<string>('');
    const [success, setSuccess] = useState<string>('');
    const [showPassword, setShowPassword] = useState<boolean>(false);
    const [showConfirmPassword, setShowConfirmPassword] = useState<boolean>(false);
    const [otpTimer, setOtpTimer] = useState<number>(0);

    // Handle input changes for registration form
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

    // Validate registration form
    const validateRegistrationForm = (): boolean => {
        if (!formData.phoneNumber.trim()) {
            setError('Vui lòng nhập số điện thoại');
            return false;
        }

        // Validate Vietnamese phone number format
        const phoneRegex = /^(\+84|0)(3[2-9]|5[6|8|9]|7[0|6-9]|8[1-6|8|9]|9[0-9])[0-9]{7}$/;
        const cleanPhone = formData.phoneNumber.replace(/\s/g, '');
        if (!phoneRegex.test(cleanPhone)) {
            setError('Số điện thoại không đúng định dạng. Vui lòng nhập số điện thoại Việt Nam hợp lệ');
            return false;
        }

        if (!formData.fullName.trim()) {
            setError('Vui lòng nhập họ và tên');
            return false;
        }

        if (formData.fullName.trim().length < 2) {
            setError('Họ và tên phải có ít nhất 2 ký tự');
            return false;
        }

        if (!formData.password) {
            setError('Vui lòng nhập mật khẩu');
            return false;
        }

        if (formData.password.length < 6) {
            setError('Mật khẩu phải có ít nhất 6 ký tự');
            return false;
        }

        if (formData.password !== formData.confirmPassword) {
            setError('Mật khẩu xác nhận không khớp');
            return false;
        }

        if (formData.email && !isValidEmail(formData.email)) {
            setError('Email không đúng định dạng');
            return false;
        }

        if (!formData.agreeToTerms) {
            setError('Vui lòng đồng ý với điều khoản sử dụng');
            return false;
        }

        return true;
    };

    // Validate email format
    const isValidEmail = (email: string): boolean => {
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        return emailRegex.test(email);
    };

    // Handle registration form submission
    const handleRegisterSubmit = async (e: React.FormEvent) => {
        e.preventDefault();

        if (!validateRegistrationForm()) {
            return;
        }

        setLoading(true);
        setError('');
        setSuccess('');

        try {
            // Call Keycloak to register user directly
            console.log('🔐 Registering user with Keycloak Admin API...');
            const userInfo = await customKeycloakService.register(
                formData.phoneNumber,
                formData.password,
                formData.fullName,
                formData.email
            );

            console.log('✅ Registration successful:', userInfo);

            const userData = {
                phoneNumber: formData.phoneNumber,
                fullName: formData.fullName,
                email: formData.email || '',
                registeredAt: new Date().toISOString(),
                username: userInfo.username,
                token: userInfo.token,
                roles: userInfo.roles
            };

            setSuccess('Đăng ký tài khoản thành công!');

            // Call success callback after a short delay
            setTimeout(() => {
                if (onRegisterSuccess) {
                    onRegisterSuccess(userData);
                }
            }, 1000);

        } catch (err: any) {
            console.error('❌ Registration failed:', err);
            if (err.message?.includes('User already exists')) {
                setError('Số điện thoại này đã được đăng ký. Vui lòng sử dụng số khác hoặc đăng nhập.');
            } else if (err.message?.includes('password')) {
                setError('Mật khẩu không đủ mạnh. Vui lòng sử dụng mật khẩu có ít nhất 8 ký tự.');
            } else {
                setError('Có lỗi xảy ra khi đăng ký: ' + err.message);
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
            // Simulate OTP verification
            await simulateApiCall(1000);

            // After OTP verified, try to create/login user with Keycloak
            console.log('🔐 Attempting to login with Keycloak after OTP verification...');

            try {
                const userInfo = await customKeycloakService.login(formData.phoneNumber, formData.password);
                console.log('✅ Login successful after registration:', userInfo);

                const userData = {
                    phoneNumber: formData.phoneNumber,
                    fullName: formData.fullName,
                    email: formData.email || '',
                    registeredAt: new Date().toISOString(),
                    username: userInfo.username,
                    token: userInfo.token,
                    roles: userInfo.roles
                };

                setSuccess('Đăng ký tài khoản thành công!');

                setTimeout(() => {
                    if (onRegisterSuccess) {
                        onRegisterSuccess(userData);
                    }
                }, 1000);

            } catch (keycloakError: any) {
                console.log('ℹ️  User not found in Keycloak, creating mock user data');

                // If Keycloak login fails, create mock user data for demo
                const userData = {
                    phoneNumber: formData.phoneNumber,
                    fullName: formData.fullName,
                    email: formData.email || '',
                    registeredAt: new Date().toISOString(),
                    username: formData.phoneNumber,
                    token: 'mock-jwt-token-' + Date.now(),
                    roles: ['USER']
                };

                setSuccess('Đăng ký tài khoản thành công! (Demo mode)');

                setTimeout(() => {
                    if (onRegisterSuccess) {
                        onRegisterSuccess(userData);
                    }
                }, 1000);
            }

        } catch (err: any) {
            console.error('❌ OTP verification failed:', err);
            setError('Mã OTP không đúng. Vui lòng kiểm tra lại.');
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

    // Go back to registration form
    const handleBackToRegister = () => {
        setCurrentStep('register');
        setVerificationData({ otpCode: '' });
        setError('');
        setSuccess('');
        setOtpTimer(0);
    };

    // Simulate API call
    const simulateApiCall = (delay: number): Promise<void> => {
        return new Promise((resolve, reject) => {
            setTimeout(() => {
                // Simulate 90% success rate
                if (Math.random() > 0.1) {
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
        <div className="phone-register-container">
            <div className="phone-register-card">
                {/* Header */}
                <div className="register-header">
                    <div className="logo-section">
                        <div className="logo-placeholder">KLB</div>
                        <h1>Kienlongbank</h1>
                    </div>
                    <h2>
                        {currentStep === 'register' ? 'Đăng ký tài khoản' : 'Xác thực số điện thoại'}
                    </h2>
                    <p className="register-subtitle">
                        {currentStep === 'register'
                            ? 'Tạo tài khoản mới với số điện thoại của bạn'
                            : `Nhập mã OTP được gửi đến ${formatPhoneNumber(formData.phoneNumber)}`
                        }
                    </p>
                </div>

                {/* Progress indicator */}
                <div className="progress-indicator">
                    <div className={`progress-step ${currentStep === 'register' ? 'active' : 'completed'}`}>
                        <div className="step-number">1</div>
                        <div className="step-label">Thông tin</div>
                    </div>
                    <div className="progress-line"></div>
                    <div className={`progress-step ${currentStep === 'verify' ? 'active' : ''}`}>
                        <div className="step-number">2</div>
                        <div className="step-label">Xác thực</div>
                    </div>
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

                {/* Registration Form */}
                {currentStep === 'register' && (
                    <form onSubmit={handleRegisterSubmit} className="register-form">
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
                            />
                        </div>

                        <div className="form-group">
                            <label htmlFor="fullName" className="form-label">
                                Họ và tên <span className="required">*</span>
                            </label>
                            <input
                                type="text"
                                id="fullName"
                                name="fullName"
                                value={formData.fullName}
                                onChange={handleInputChange}
                                placeholder="Nhập họ và tên đầy đủ"
                                className="form-input"
                                disabled={loading}
                            />
                        </div>

                        <div className="form-group">
                            <label htmlFor="email" className="form-label">
                                Email (tùy chọn)
                            </label>
                            <input
                                type="email"
                                id="email"
                                name="email"
                                value={formData.email}
                                onChange={handleInputChange}
                                placeholder="Nhập địa chỉ email"
                                className="form-input"
                                disabled={loading}
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
                                    placeholder="Nhập mật khẩu (tối thiểu 6 ký tự)"
                                    className="form-input"
                                    disabled={loading}
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

                        <div className="form-group">
                            <label htmlFor="confirmPassword" className="form-label">
                                Xác nhận mật khẩu <span className="required">*</span>
                            </label>
                            <div className="password-input-container">
                                <input
                                    type={showConfirmPassword ? "text" : "password"}
                                    id="confirmPassword"
                                    name="confirmPassword"
                                    value={formData.confirmPassword}
                                    onChange={handleInputChange}
                                    placeholder="Nhập lại mật khẩu"
                                    className="form-input"
                                    disabled={loading}
                                />
                                <button
                                    type="button"
                                    className="password-toggle"
                                    onClick={() => setShowConfirmPassword(!showConfirmPassword)}
                                    disabled={loading}
                                >
                                    {showConfirmPassword ? "🙈" : "👁️"}
                                </button>
                            </div>
                        </div>

                        <div className="form-group checkbox-group">
                            <label className="checkbox-label">
                                <input
                                    type="checkbox"
                                    name="agreeToTerms"
                                    checked={formData.agreeToTerms}
                                    onChange={handleInputChange}
                                    disabled={loading}
                                    className="checkbox-input"
                                />
                                <span className="checkmark"></span>
                                Tôi đồng ý với{' '}
                                <a href="#" className="terms-link">Điều khoản sử dụng</a>{' '}
                                và{' '}
                                <a href="#" className="terms-link">Chính sách bảo mật</a>
                            </label>
                        </div>

                        <button
                            type="submit"
                            className="register-button"
                            disabled={loading}
                        >
                            {loading ? (
                                <span className="loading-spinner">⏳ Đang xử lý...</span>
                            ) : (
                                'Tiếp tục'
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
                                onClick={handleBackToRegister}
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
                <div className="register-footer">
                    <p>
                        Đã có tài khoản?{' '}
                        <button
                            type="button"
                            onClick={onSwitchToLogin}
                            className="switch-button"
                            disabled={loading}
                        >
                            Đăng nhập ngay
                        </button>
                    </p>
                </div>
            </div>
        </div>
    );
};

export default PhoneRegisterPage;
