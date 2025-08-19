import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import useKeycloakAuth from '../hooks/useKeycloakAuth';

interface CreateAccountForm {
    accountType: string;
    initialDeposit: number;
}

const CreateAccountPage: React.FC = () => {
    const navigate = useNavigate();
    const { userInfo, token } = useKeycloakAuth();
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState<string | null>(null);
    const [success, setSuccess] = useState<string | null>(null);

    const [formData, setFormData] = useState<CreateAccountForm>({
        accountType: 'CHECKING',
        initialDeposit: 0
    });

    const accountTypes = [
        { value: 'CHECKING', label: '🏦 Tài khoản thanh toán', description: 'Dành cho giao dịch hàng ngày' },
        { value: 'SAVINGS', label: '💰 Tài khoản tiết kiệm', description: 'Dành cho tích lũy tiền' },
        { value: 'BUSINESS', label: '🏢 Tài khoản doanh nghiệp', description: 'Dành cho doanh nghiệp' }
    ];

    const handleInputChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
        const { name, value } = e.target;
        setFormData(prev => ({
            ...prev,
            [name]: name === 'initialDeposit' ? parseFloat(value) || 0 : value
        }));
    };

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setLoading(true);
        setError(null);
        setSuccess(null);

        try {
            if (!token) {
                throw new Error('Không thể lấy token xác thực');
            }

            // API call to create account - Use relative URL to leverage proxy/baseURL
            const response = await fetch('/api/accounts', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`
                },
                body: JSON.stringify({
                    accountType: formData.accountType,
                    balance: formData.initialDeposit
                })
            });

            if (!response.ok) {
                const errorData = await response.json().catch(() => null);
                throw new Error(errorData?.message || `Lỗi ${response.status}: Không thể tạo tài khoản`);
            }

            const result = await response.json();
            setSuccess(`✅ Tạo tài khoản thành công! Số tài khoản: ${result.accountNumber}`);

            // Reset form
            setFormData({
                accountType: 'CHECKING',
                initialDeposit: 0
            });

            // Redirect to dashboard after 3 seconds
            setTimeout(() => {
                navigate('/dashboard');
            }, 3000);

        } catch (err) {
            console.error('Create account error:', err);
            setError(err instanceof Error ? err.message : 'Có lỗi xảy ra khi tạo tài khoản');
        } finally {
            setLoading(false);
        }
    };

    return (
        <div style={{ padding: '20px', maxWidth: '600px', margin: '0 auto' }}>
            {/* Header */}
            <div style={{
                display: 'flex',
                alignItems: 'center',
                marginBottom: '30px',
                padding: '20px',
                backgroundColor: '#f8f9fa',
                borderRadius: '8px',
                borderLeft: '4px solid #28a745'
            }}>
                <h1 style={{ margin: '0', color: '#28a745', fontSize: '24px' }}>
                    🏦 Tạo tài khoản mới
                </h1>
            </div>

            {/* User Info */}
            <div style={{
                backgroundColor: '#e8f4fd',
                padding: '15px',
                borderRadius: '8px',
                marginBottom: '20px',
                border: '1px solid #b8daff'
            }}>
                <h3 style={{ margin: '0 0 10px 0', color: '#004085' }}>👤 Thông tin khách hàng</h3>
                <p style={{ margin: '5px 0', color: '#004085' }}>
                    <strong>Tên đăng nhập:</strong> {userInfo?.username || 'N/A'}
                </p>
                <p style={{ margin: '5px 0', color: '#004085' }}>
                    <strong>Quyền:</strong> {userInfo?.roles?.join(', ') || 'N/A'}
                </p>
            </div>

            {/* Create Account Form */}
            <div style={{
                backgroundColor: 'white',
                padding: '30px',
                borderRadius: '8px',
                boxShadow: '0 2px 4px rgba(0,0,0,0.1)'
            }}>
                <form onSubmit={handleSubmit}>
                    {/* Account Type Selection */}
                    <div style={{ marginBottom: '25px' }}>
                        <label style={{
                            display: 'block',
                            marginBottom: '10px',
                            fontWeight: 'bold',
                            color: '#333'
                        }}>
                            Loại tài khoản *
                        </label>

                        <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
                            {accountTypes.map(type => (
                                <label
                                    key={type.value}
                                    style={{
                                        display: 'flex',
                                        alignItems: 'center',
                                        padding: '12px',
                                        border: `2px solid ${formData.accountType === type.value ? '#28a745' : '#ddd'}`,
                                        borderRadius: '8px',
                                        cursor: 'pointer',
                                        backgroundColor: formData.accountType === type.value ? '#f8fff8' : 'white'
                                    }}
                                >
                                    <input
                                        type="radio"
                                        name="accountType"
                                        value={type.value}
                                        checked={formData.accountType === type.value}
                                        onChange={handleInputChange}
                                        style={{ marginRight: '10px' }}
                                    />
                                    <div>
                                        <div style={{ fontWeight: 'bold', marginBottom: '4px' }}>
                                            {type.label}
                                        </div>
                                        <div style={{ fontSize: '14px', color: '#666' }}>
                                            {type.description}
                                        </div>
                                    </div>
                                </label>
                            ))}
                        </div>
                    </div>

                    {/* Initial Deposit */}
                    <div style={{ marginBottom: '25px' }}>
                        <label style={{
                            display: 'block',
                            marginBottom: '8px',
                            fontWeight: 'bold',
                            color: '#333'
                        }}>
                            Số tiền gửi ban đầu (VNĐ)
                        </label>
                        <input
                            type="number"
                            name="initialDeposit"
                            value={formData.initialDeposit}
                            onChange={handleInputChange}
                            min="0"
                            step="1000"
                            placeholder="Nhập số tiền (có thể để 0)"
                            style={{
                                width: '100%',
                                padding: '12px',
                                border: '2px solid #ddd',
                                borderRadius: '6px',
                                fontSize: '16px',
                                boxSizing: 'border-box'
                            }}
                        />
                        <small style={{ color: '#666', fontSize: '14px' }}>
                            Số tiền tối thiểu: 0 VNĐ. Bạn có thể nạp tiền sau khi tạo tài khoản.
                        </small>
                    </div>

                    {/* Error Message */}
                    {error && (
                        <div style={{
                            backgroundColor: '#f8d7da',
                            color: '#721c24',
                            padding: '12px',
                            borderRadius: '6px',
                            marginBottom: '20px',
                            border: '1px solid #f5c6cb'
                        }}>
                            ❌ {error}
                        </div>
                    )}

                    {/* Success Message */}
                    {success && (
                        <div style={{
                            backgroundColor: '#d4edda',
                            color: '#155724',
                            padding: '12px',
                            borderRadius: '6px',
                            marginBottom: '20px',
                            border: '1px solid #c3e6cb'
                        }}>
                            {success}
                            <br />
                            <small>Đang chuyển về trang chủ...</small>
                        </div>
                    )}

                    {/* Action Buttons */}
                    <div style={{
                        display: 'flex',
                        gap: '15px',
                        justifyContent: 'space-between'
                    }}>
                        <button
                            type="button"
                            onClick={() => navigate('/dashboard')}
                            disabled={loading}
                            style={{
                                flex: 1,
                                padding: '12px 20px',
                                backgroundColor: '#6c757d',
                                color: 'white',
                                border: 'none',
                                borderRadius: '6px',
                                fontSize: '16px',
                                cursor: loading ? 'not-allowed' : 'pointer',
                                opacity: loading ? 0.6 : 1
                            }}
                        >
                            ← Quay lại
                        </button>

                        <button
                            type="submit"
                            disabled={loading}
                            style={{
                                flex: 2,
                                padding: '12px 20px',
                                backgroundColor: loading ? '#ccc' : '#28a745',
                                color: 'white',
                                border: 'none',
                                borderRadius: '6px',
                                fontSize: '16px',
                                cursor: loading ? 'not-allowed' : 'pointer',
                                fontWeight: 'bold'
                            }}
                        >
                            {loading ? '⏳ Đang tạo...' : '🏦 Tạo tài khoản'}
                        </button>
                    </div>
                </form>
            </div>

            {/* Info Section */}
            <div style={{
                backgroundColor: '#fff3cd',
                padding: '15px',
                borderRadius: '8px',
                marginTop: '20px',
                border: '1px solid #ffeaa7'
            }}>
                <h4 style={{ margin: '0 0 10px 0', color: '#856404' }}>💡 Lưu ý quan trọng:</h4>
                <ul style={{ margin: '0', paddingLeft: '20px', color: '#856404' }}>
                    <li>Sau khi tạo tài khoản, bạn có thể chuyển tiền và thực hiện giao dịch</li>
                    <li>Số tài khoản sẽ được tự động tạo và không thể thay đổi</li>
                    <li>Bạn có thể tạo nhiều tài khoản với các loại khác nhau</li>
                    <li>Liên hệ quản trị viên nếu cần hỗ trợ</li>
                </ul>
            </div>
        </div>
    );
};

export default CreateAccountPage;
