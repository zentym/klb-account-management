import React, { useState } from 'react';
import api from '../config/api';
import useKeycloakAuth from '../hooks/useKeycloakAuth';

interface LoanApplicationRequest {
    amount: number;
    term: number;
    purpose: string;
    monthlyIncome: number;
    employmentStatus: string;
    collateralValue?: number;
    collateralDescription?: string;
}

interface ApiResponse<T> {
    status: string;
    data: T;
    message: string;
}

export const LoanApplicationPage: React.FC = () => {
    const { userInfo } = useKeycloakAuth();
    const [formData, setFormData] = useState<LoanApplicationRequest>({
        amount: 0,
        term: 12,
        purpose: '',
        monthlyIncome: 0,
        employmentStatus: '',
        collateralValue: 0,
        collateralDescription: ''
    });

    const [loading, setLoading] = useState<boolean>(false);
    const [error, setError] = useState<string>('');
    const [success, setSuccess] = useState<boolean>(false);

    // Các tùy chọn có sẵn
    const loanPurposes = [
        'Mua nhà',
        'Mua xe',
        'Kinh doanh',
        'Học tập',
        'Du lịch',
        'Y tế',
        'Cải tạo nhà',
        'Khác'
    ];

    const employmentStatuses = [
        'Nhân viên công ty',
        'Công chức',
        'Kinh doanh tự do',
        'Nông dân',
        'Sinh viên',
        'Khác'
    ];

    const loanTerms = [
        { value: 6, label: '6 tháng' },
        { value: 12, label: '12 tháng' },
        { value: 24, label: '24 tháng' },
        { value: 36, label: '36 tháng' },
        { value: 48, label: '48 tháng' },
        { value: 60, label: '60 tháng' }
    ];

    const handleInputChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) => {
        const { name, value } = e.target;
        setFormData(prev => ({
            ...prev,
            [name]: name === 'amount' || name === 'term' || name === 'monthlyIncome' || name === 'collateralValue'
                ? parseFloat(value) || 0
                : value
        }));
    };

    const formatCurrency = (amount: number) => {
        return new Intl.NumberFormat('vi-VN', {
            style: 'currency',
            currency: 'VND'
        }).format(amount);
    };

    const validateForm = (): boolean => {
        if (formData.amount <= 0) {
            setError('Số tiền vay phải lớn hơn 0');
            return false;
        }
        if (formData.amount > 10000000000) { // 10 tỷ VND
            setError('Số tiền vay không được vượt quá 10 tỷ VND');
            return false;
        }
        if (!formData.purpose.trim()) {
            setError('Vui lòng chọn mục đích vay');
            return false;
        }
        if (formData.monthlyIncome <= 0) {
            setError('Thu nhập hàng tháng phải lớn hơn 0');
            return false;
        }
        if (!formData.employmentStatus.trim()) {
            setError('Vui lòng chọn trạng thái công việc');
            return false;
        }

        // Kiểm tra khả năng thanh toán (thu nhập phải ít nhất gấp 3 lần số tiền trả hàng tháng)
        const monthlyPayment = formData.amount / formData.term;
        if (formData.monthlyIncome < monthlyPayment * 3) {
            setError('Thu nhập của bạn có thể không đủ để thanh toán khoản vay này. Vui lòng giảm số tiền hoặc tăng thời hạn vay.');
            return false;
        }

        return true;
    };

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setError('');
        setSuccess(false);

        if (!validateForm()) {
            return;
        }

        setLoading(true);

        try {
            console.log('📤 Submitting loan application:', formData);

            // Chuẩn bị dữ liệu gửi đi
            const requestData = {
                ...formData,
                // Xóa các trường tùy chọn nếu không có giá trị
                collateralValue: formData.collateralValue || undefined,
                collateralDescription: formData.collateralDescription?.trim() || undefined
            };

            const response = await api.post<ApiResponse<any>>('/api/loans/apply', requestData);
            console.log('📥 Loan application response:', response.data);

            setSuccess(true);
            setError('');

            // Reset form
            setFormData({
                amount: 0,
                term: 12,
                purpose: '',
                monthlyIncome: 0,
                employmentStatus: '',
                collateralValue: 0,
                collateralDescription: ''
            });

        } catch (err: any) {
            console.error('❌ Error submitting loan application:', err);
            const errorMessage = err.response?.data?.message || err.message || 'Có lỗi xảy ra khi gửi đơn vay';
            setError(errorMessage);
            setSuccess(false);
        } finally {
            setLoading(false);
        }
    };

    const calculateMonthlyPayment = () => {
        if (formData.amount && formData.term) {
            return formData.amount / formData.term;
        }
        return 0;
    };

    if (success) {
        return (
            <div style={{
                maxWidth: '600px',
                margin: '0 auto',
                padding: '40px 20px',
                textAlign: 'center'
            }}>
                <div style={{
                    backgroundColor: '#e8f5e8',
                    border: '1px solid #4caf50',
                    borderRadius: '8px',
                    padding: '30px',
                    marginBottom: '20px'
                }}>
                    <h2 style={{ color: '#2e7d32', marginBottom: '15px' }}>
                        ✅ Đã gửi đơn vay thành công!
                    </h2>
                    <p style={{ fontSize: '16px', marginBottom: '20px' }}>
                        Đơn vay của bạn đã được gửi thành công. Vui lòng chờ duyệt.
                    </p>
                    <p style={{ color: '#666', fontSize: '14px' }}>
                        Chúng tôi sẽ xem xét hồ sơ và liên hệ với bạn trong vòng 2-3 ngày làm việc.
                    </p>
                </div>

                <button
                    onClick={() => setSuccess(false)}
                    style={{
                        padding: '12px 24px',
                        backgroundColor: '#1976d2',
                        color: 'white',
                        border: 'none',
                        borderRadius: '4px',
                        cursor: 'pointer',
                        fontSize: '16px',
                        marginRight: '10px'
                    }}
                >
                    Gửi đơn vay khác
                </button>

                <button
                    onClick={() => window.location.href = '/dashboard'}
                    style={{
                        padding: '12px 24px',
                        backgroundColor: '#4caf50',
                        color: 'white',
                        border: 'none',
                        borderRadius: '4px',
                        cursor: 'pointer',
                        fontSize: '16px'
                    }}
                >
                    Về trang chủ
                </button>
            </div>
        );
    }

    return (
        <div style={{
            maxWidth: '800px',
            margin: '0 auto',
            padding: '20px'
        }}>
            <h2 style={{
                textAlign: 'center',
                marginBottom: '30px',
                color: '#1976d2'
            }}>
                💰 Đăng ký khoản vay
            </h2>

            <div style={{
                backgroundColor: '#f8f9fa',
                padding: '20px',
                borderRadius: '8px',
                marginBottom: '20px'
            }}>
                <h4>👤 Thông tin người vay</h4>
                <p><strong>Tên:</strong> {userInfo?.username}</p>
                <p><strong>Email:</strong> {userInfo?.email || 'Chưa cập nhật'}</p>
            </div>

            <form onSubmit={handleSubmit} style={{
                backgroundColor: 'white',
                padding: '30px',
                borderRadius: '8px',
                boxShadow: '0 2px 10px rgba(0,0,0,0.1)'
            }}>
                {/* Số tiền vay */}
                <div style={{ marginBottom: '20px' }}>
                    <label style={{
                        display: 'block',
                        marginBottom: '8px',
                        fontWeight: 'bold'
                    }}>
                        Số tiền vay (VND) *
                    </label>
                    <input
                        type="number"
                        name="amount"
                        value={formData.amount || ''}
                        onChange={handleInputChange}
                        min="1000000"
                        max="10000000000"
                        step="1000000"
                        placeholder="Ví dụ: 100000000"
                        style={{
                            width: '100%',
                            padding: '12px',
                            border: '1px solid #ddd',
                            borderRadius: '4px',
                            fontSize: '16px'
                        }}
                        required
                    />
                    {formData.amount > 0 && (
                        <p style={{ color: '#666', fontSize: '14px', marginTop: '5px' }}>
                            {formatCurrency(formData.amount)}
                        </p>
                    )}
                </div>

                {/* Thời hạn vay */}
                <div style={{ marginBottom: '20px' }}>
                    <label style={{
                        display: 'block',
                        marginBottom: '8px',
                        fontWeight: 'bold'
                    }}>
                        Thời hạn vay *
                    </label>
                    <select
                        name="term"
                        value={formData.term}
                        onChange={handleInputChange}
                        style={{
                            width: '100%',
                            padding: '12px',
                            border: '1px solid #ddd',
                            borderRadius: '4px',
                            fontSize: '16px'
                        }}
                        required
                    >
                        {loanTerms.map(term => (
                            <option key={term.value} value={term.value}>
                                {term.label}
                            </option>
                        ))}
                    </select>
                </div>

                {/* Số tiền trả hàng tháng dự kiến */}
                {formData.amount > 0 && formData.term > 0 && (
                    <div style={{
                        backgroundColor: '#e3f2fd',
                        padding: '15px',
                        borderRadius: '4px',
                        marginBottom: '20px'
                    }}>
                        <p style={{ margin: 0, fontWeight: 'bold' }}>
                            💡 Số tiền trả hàng tháng dự kiến (chưa bao gồm lãi suất): {formatCurrency(calculateMonthlyPayment())}
                        </p>
                    </div>
                )}

                {/* Mục đích vay */}
                <div style={{ marginBottom: '20px' }}>
                    <label style={{
                        display: 'block',
                        marginBottom: '8px',
                        fontWeight: 'bold'
                    }}>
                        Mục đích vay *
                    </label>
                    <select
                        name="purpose"
                        value={formData.purpose}
                        onChange={handleInputChange}
                        style={{
                            width: '100%',
                            padding: '12px',
                            border: '1px solid #ddd',
                            borderRadius: '4px',
                            fontSize: '16px'
                        }}
                        required
                    >
                        <option value="">Chọn mục đích vay</option>
                        {loanPurposes.map(purpose => (
                            <option key={purpose} value={purpose}>
                                {purpose}
                            </option>
                        ))}
                    </select>
                </div>

                {/* Thu nhập hàng tháng */}
                <div style={{ marginBottom: '20px' }}>
                    <label style={{
                        display: 'block',
                        marginBottom: '8px',
                        fontWeight: 'bold'
                    }}>
                        Thu nhập hàng tháng (VND) *
                    </label>
                    <input
                        type="number"
                        name="monthlyIncome"
                        value={formData.monthlyIncome || ''}
                        onChange={handleInputChange}
                        min="1000000"
                        step="1000000"
                        placeholder="Ví dụ: 20000000"
                        style={{
                            width: '100%',
                            padding: '12px',
                            border: '1px solid #ddd',
                            borderRadius: '4px',
                            fontSize: '16px'
                        }}
                        required
                    />
                    {formData.monthlyIncome > 0 && (
                        <p style={{ color: '#666', fontSize: '14px', marginTop: '5px' }}>
                            {formatCurrency(formData.monthlyIncome)}
                        </p>
                    )}
                </div>

                {/* Trạng thái công việc */}
                <div style={{ marginBottom: '20px' }}>
                    <label style={{
                        display: 'block',
                        marginBottom: '8px',
                        fontWeight: 'bold'
                    }}>
                        Trạng thái công việc *
                    </label>
                    <select
                        name="employmentStatus"
                        value={formData.employmentStatus}
                        onChange={handleInputChange}
                        style={{
                            width: '100%',
                            padding: '12px',
                            border: '1px solid #ddd',
                            borderRadius: '4px',
                            fontSize: '16px'
                        }}
                        required
                    >
                        <option value="">Chọn trạng thái công việc</option>
                        {employmentStatuses.map(status => (
                            <option key={status} value={status}>
                                {status}
                            </option>
                        ))}
                    </select>
                </div>

                {/* Thông tin tài sản đảm bảo (tùy chọn) */}
                <div style={{
                    border: '1px solid #e0e0e0',
                    borderRadius: '8px',
                    padding: '20px',
                    marginBottom: '20px',
                    backgroundColor: '#fafafa'
                }}>
                    <h4 style={{ marginBottom: '15px', color: '#666' }}>
                        🏠 Tài sản đảm bảo (tùy chọn)
                    </h4>

                    <div style={{ marginBottom: '15px' }}>
                        <label style={{
                            display: 'block',
                            marginBottom: '8px',
                            fontWeight: 'bold'
                        }}>
                            Giá trị tài sản (VND)
                        </label>
                        <input
                            type="number"
                            name="collateralValue"
                            value={formData.collateralValue || ''}
                            onChange={handleInputChange}
                            min="0"
                            step="1000000"
                            placeholder="Ví dụ: 500000000"
                            style={{
                                width: '100%',
                                padding: '12px',
                                border: '1px solid #ddd',
                                borderRadius: '4px',
                                fontSize: '16px'
                            }}
                        />
                        {formData.collateralValue && formData.collateralValue > 0 && (
                            <p style={{ color: '#666', fontSize: '14px', marginTop: '5px' }}>
                                {formatCurrency(formData.collateralValue)}
                            </p>
                        )}
                    </div>

                    <div>
                        <label style={{
                            display: 'block',
                            marginBottom: '8px',
                            fontWeight: 'bold'
                        }}>
                            Mô tả tài sản
                        </label>
                        <textarea
                            name="collateralDescription"
                            value={formData.collateralDescription || ''}
                            onChange={handleInputChange}
                            placeholder="Ví dụ: Nhà riêng tại Quận 1, TP.HCM, diện tích 80m2..."
                            rows={3}
                            style={{
                                width: '100%',
                                padding: '12px',
                                border: '1px solid #ddd',
                                borderRadius: '4px',
                                fontSize: '16px',
                                resize: 'vertical'
                            }}
                        />
                    </div>
                </div>

                {/* Thông báo lỗi */}
                {error && (
                    <div style={{
                        backgroundColor: '#ffebee',
                        border: '1px solid #f44336',
                        borderRadius: '4px',
                        padding: '12px',
                        marginBottom: '20px',
                        color: '#c62828'
                    }}>
                        ❌ {error}
                    </div>
                )}

                {/* Buttons */}
                <div style={{
                    display: 'flex',
                    gap: '15px',
                    justifyContent: 'center',
                    marginTop: '30px'
                }}>
                    <button
                        type="button"
                        onClick={() => window.history.back()}
                        style={{
                            padding: '12px 24px',
                            backgroundColor: '#6c757d',
                            color: 'white',
                            border: 'none',
                            borderRadius: '4px',
                            cursor: 'pointer',
                            fontSize: '16px'
                        }}
                    >
                        ← Quay lại
                    </button>

                    <button
                        type="submit"
                        disabled={loading}
                        style={{
                            padding: '12px 24px',
                            backgroundColor: loading ? '#ccc' : '#1976d2',
                            color: 'white',
                            border: 'none',
                            borderRadius: '4px',
                            cursor: loading ? 'not-allowed' : 'pointer',
                            fontSize: '16px'
                        }}
                    >
                        {loading ? '⏳ Đang gửi...' : '✈️ Gửi đơn vay'}
                    </button>
                </div>
            </form>
        </div>
    );
};

export default LoanApplicationPage;
