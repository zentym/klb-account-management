import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import useCustomAuth from '../hooks/useCustomAuth';
import api from '../config/api';
import customKeycloakService from '../services/customKeycloakService';

interface CustomerInfo {
    id?: number;
    fullName: string;
    email: string;
    phone: string;
    address: string;
    dateOfBirth?: string;
    idNumber?: string;
    createdAt?: string;
    updatedAt?: string;
}

interface Account {
    id: number;
    accountNumber: string;
    accountType: string;
    balance: number;
    status: string;
    openDate: string;
}

const CustomerInfoPage: React.FC = () => {
    const navigate = useNavigate();
    const { userInfo, isAuthenticated, hasRole } = useCustomAuth();
    const [customerInfo, setCustomerInfo] = useState<CustomerInfo>({
        fullName: '',
        email: '',
        phone: '',
        address: '',
        dateOfBirth: '',
        idNumber: ''
    });
    const [accounts, setAccounts] = useState<Account[]>([]);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');
    const [success, setSuccess] = useState('');
    const [isEditing, setIsEditing] = useState(false);
    const [editForm, setEditForm] = useState<CustomerInfo>({
        fullName: '',
        email: '',
        phone: '',
        address: '',
        dateOfBirth: '',
        idNumber: ''
    });

    // Lấy thông tin khách hàng
    const fetchCustomerInfo = async () => {
        try {
            setLoading(true);
            setError('');

            // Gọi trực tiếp Customer Service (port 8082)
            const token = customKeycloakService.getToken();
            const response = await fetch('http://localhost:8082/api/customers/my-info', {
                method: 'GET',
                headers: {
                    'Content-Type': 'application/json',
                    ...(token ? { 'Authorization': `Bearer ${token}` } : {})
                }
            });

            if (!response.ok) {
                throw new Error(`HTTP ${response.status}: ${response.statusText}`);
            }

            const data = await response.json();
            const customerData = data.success ? data.data : data;

            setCustomerInfo(customerData);
            setEditForm(customerData);
        } catch (err: any) {
            console.error('Error fetching customer info:', err);
            setError('Không thể tải thông tin khách hàng. Vui lòng thử lại sau.');
        } finally {
            setLoading(false);
        }
    };

    // Lấy danh sách tài khoản
    const fetchMyAccounts = async () => {
        try {
            // Gọi Main App để lấy tài khoản (vì tài khoản thuộc về Main App)
            const response = await api.get('/customers/1/accounts');
            setAccounts(response.data);
        } catch (err: any) {
            console.error('Error fetching accounts:', err);
            // Không hiển thị lỗi này vì tài khoản có thể chưa có
        }
    };

    useEffect(() => {
        if (isAuthenticated) {
            fetchCustomerInfo();
            fetchMyAccounts();
        }
    }, [isAuthenticated]);

    const handleInputChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
        const { name, value } = e.target;
        setEditForm(prev => ({
            ...prev,
            [name]: value
        }));
    };

    const handleSaveChanges = async (e: React.FormEvent) => {
        e.preventDefault();
        try {
            setLoading(true);
            setError('');
            setSuccess('');

            // Gọi trực tiếp Customer Service để cập nhật thông tin
            const token = customKeycloakService.getToken();
            const response = await fetch('http://localhost:8082/api/customers/my-info', {
                method: 'PUT',
                headers: {
                    'Content-Type': 'application/json',
                    ...(token ? { 'Authorization': `Bearer ${token}` } : {})
                },
                body: JSON.stringify(editForm)
            });

            if (!response.ok) {
                throw new Error(`HTTP ${response.status}: ${response.statusText}`);
            }

            const data = await response.json();
            const updatedCustomer = data.success ? data.data : data;

            setCustomerInfo(updatedCustomer);
            setIsEditing(false);
            setSuccess('Thông tin đã được cập nhật thành công!');
        } catch (err: any) {
            console.error('Error updating customer info:', err);
            setError('Không thể cập nhật thông tin. Vui lòng thử lại sau.');
        } finally {
            setLoading(false);
        }
    };

    const handleCancelEdit = () => {
        setEditForm(customerInfo);
        setIsEditing(false);
        setError('');
        setSuccess('');
    };

    const formatCurrency = (amount: number) => {
        return new Intl.NumberFormat('vi-VN', {
            style: 'currency',
            currency: 'VND'
        }).format(amount);
    };

    const formatDate = (dateString: string) => {
        if (!dateString) return '-';
        return new Date(dateString).toLocaleDateString('vi-VN');
    };

    const getAccountTypeIcon = (type: string) => {
        switch (type) {
            case 'SAVINGS':
                return '💰';
            case 'CHECKING':
                return '💳';
            case 'CREDIT':
                return '🎯';
            default:
                return '🏦';
        }
    };

    const getAccountTypeName = (type: string) => {
        switch (type) {
            case 'SAVINGS':
                return 'Tiết kiệm';
            case 'CHECKING':
                return 'Thanh toán';
            case 'CREDIT':
                return 'Tín dụng';
            default:
                return type;
        }
    };

    const getStatusColor = (status: string) => {
        switch (status) {
            case 'ACTIVE':
                return '#4caf50';
            case 'CLOSED':
                return '#f44336';
            case 'SUSPENDED':
                return '#ff9800';
            default:
                return '#666';
        }
    };

    const getStatusText = (status: string) => {
        switch (status) {
            case 'ACTIVE':
                return 'Hoạt động';
            case 'CLOSED':
                return 'Đã đóng';
            case 'SUSPENDED':
                return 'Tạm ngừng';
            default:
                return status;
        }
    };

    if (!isAuthenticated) {
        return (
            <div style={{ textAlign: 'center', padding: '40px' }}>
                <h2>🔐 Vui lòng đăng nhập</h2>
                <p>Bạn cần đăng nhập để xem thông tin cá nhân.</p>
                <button
                    onClick={() => navigate('/login')}
                    style={{
                        padding: '10px 20px',
                        backgroundColor: '#1976d2',
                        color: 'white',
                        border: 'none',
                        borderRadius: '4px',
                        cursor: 'pointer'
                    }}
                >
                    Đăng nhập
                </button>
            </div>
        );
    }

    return (
        <div style={{
            maxWidth: '1200px',
            margin: '0 auto',
            padding: '20px',
            fontFamily: 'Arial, sans-serif'
        }}>
            {/* Header */}
            <div style={{
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'center',
                marginBottom: '30px',
                padding: '20px',
                backgroundColor: '#1976d2',
                color: 'white',
                borderRadius: '8px'
            }}>
                <div>
                    <h1 style={{ margin: '0 0 10px 0', fontSize: '28px' }}>
                        👤 Thông tin cá nhân
                    </h1>
                    <p style={{ margin: '0', opacity: '0.9' }}>
                        Quản lý thông tin tài khoản và tài chính của bạn
                    </p>
                </div>
                <button
                    onClick={() => navigate('/dashboard')}
                    style={{
                        padding: '8px 16px',
                        backgroundColor: 'rgba(255,255,255,0.2)',
                        color: 'white',
                        border: '1px solid rgba(255,255,255,0.3)',
                        borderRadius: '4px',
                        cursor: 'pointer',
                        fontSize: '14px'
                    }}
                    onMouseOver={(e) => {
                        e.currentTarget.style.backgroundColor = 'rgba(255,255,255,0.3)';
                    }}
                    onMouseOut={(e) => {
                        e.currentTarget.style.backgroundColor = 'rgba(255,255,255,0.2)';
                    }}
                >
                    ← Về Dashboard
                </button>
            </div>

            {/* Error/Success Messages */}
            {error && (
                <div style={{
                    padding: '15px',
                    backgroundColor: '#ffebee',
                    color: '#c62828',
                    borderRadius: '4px',
                    marginBottom: '20px',
                    border: '1px solid #ffcdd2'
                }}>
                    ❌ {error}
                </div>
            )}

            {success && (
                <div style={{
                    padding: '15px',
                    backgroundColor: '#e8f5e8',
                    color: '#2e7d32',
                    borderRadius: '4px',
                    marginBottom: '20px',
                    border: '1px solid #c8e6c9'
                }}>
                    ✅ {success}
                </div>
            )}

            {loading && (
                <div style={{
                    textAlign: 'center',
                    padding: '20px',
                    color: '#666'
                }}>
                    ⏳ Đang tải...
                </div>
            )}

            <div style={{
                display: 'grid',
                gridTemplateColumns: '1fr 1fr',
                gap: '30px',
                alignItems: 'start'
            }}>
                {/* Thông tin cá nhân */}
                <div style={{
                    backgroundColor: 'white',
                    padding: '25px',
                    borderRadius: '8px',
                    boxShadow: '0 4px 6px rgba(0,0,0,0.1)',
                    border: '1px solid #e0e0e0'
                }}>
                    <div style={{
                        display: 'flex',
                        justifyContent: 'space-between',
                        alignItems: 'center',
                        marginBottom: '20px',
                        paddingBottom: '15px',
                        borderBottom: '2px solid #e0e0e0'
                    }}>
                        <h3 style={{
                            margin: '0',
                            color: '#1976d2',
                            display: 'flex',
                            alignItems: 'center',
                            gap: '10px'
                        }}>
                            📋 Thông tin cá nhân
                        </h3>
                        {!isEditing && (
                            <button
                                onClick={() => setIsEditing(true)}
                                style={{
                                    padding: '8px 16px',
                                    backgroundColor: '#4caf50',
                                    color: 'white',
                                    border: 'none',
                                    borderRadius: '4px',
                                    cursor: 'pointer',
                                    fontSize: '14px',
                                    display: 'flex',
                                    alignItems: 'center',
                                    gap: '5px'
                                }}
                            >
                                ✏️ Chỉnh sửa
                            </button>
                        )}
                    </div>

                    {isEditing ? (
                        <form onSubmit={handleSaveChanges}>
                            <div style={{ display: 'grid', gap: '15px' }}>
                                <div>
                                    <label style={{ display: 'block', marginBottom: '5px', fontWeight: '500' }}>
                                        Họ và tên *
                                    </label>
                                    <input
                                        type="text"
                                        name="fullName"
                                        value={editForm.fullName}
                                        onChange={handleInputChange}
                                        required
                                        style={{
                                            width: '100%',
                                            padding: '10px',
                                            borderRadius: '4px',
                                            border: '1px solid #ccc',
                                            fontSize: '14px'
                                        }}
                                    />
                                </div>
                                <div>
                                    <label style={{ display: 'block', marginBottom: '5px', fontWeight: '500' }}>
                                        Email *
                                    </label>
                                    <input
                                        type="email"
                                        name="email"
                                        value={editForm.email}
                                        onChange={handleInputChange}
                                        required
                                        style={{
                                            width: '100%',
                                            padding: '10px',
                                            borderRadius: '4px',
                                            border: '1px solid #ccc',
                                            fontSize: '14px'
                                        }}
                                    />
                                </div>
                                <div>
                                    <label style={{ display: 'block', marginBottom: '5px', fontWeight: '500' }}>
                                        Số điện thoại
                                    </label>
                                    <input
                                        type="tel"
                                        name="phone"
                                        value={editForm.phone}
                                        onChange={handleInputChange}
                                        style={{
                                            width: '100%',
                                            padding: '10px',
                                            borderRadius: '4px',
                                            border: '1px solid #ccc',
                                            fontSize: '14px'
                                        }}
                                    />
                                </div>
                                <div>
                                    <label style={{ display: 'block', marginBottom: '5px', fontWeight: '500' }}>
                                        Địa chỉ
                                    </label>
                                    <textarea
                                        name="address"
                                        value={editForm.address}
                                        onChange={handleInputChange}
                                        rows={3}
                                        style={{
                                            width: '100%',
                                            padding: '10px',
                                            borderRadius: '4px',
                                            border: '1px solid #ccc',
                                            fontSize: '14px',
                                            resize: 'vertical'
                                        }}
                                    />
                                </div>
                                <div>
                                    <label style={{ display: 'block', marginBottom: '5px', fontWeight: '500' }}>
                                        Ngày sinh
                                    </label>
                                    <input
                                        type="date"
                                        name="dateOfBirth"
                                        value={editForm.dateOfBirth}
                                        onChange={handleInputChange}
                                        style={{
                                            width: '100%',
                                            padding: '10px',
                                            borderRadius: '4px',
                                            border: '1px solid #ccc',
                                            fontSize: '14px'
                                        }}
                                    />
                                </div>
                                <div>
                                    <label style={{ display: 'block', marginBottom: '5px', fontWeight: '500' }}>
                                        Số CMND/CCCD
                                    </label>
                                    <input
                                        type="text"
                                        name="idNumber"
                                        value={editForm.idNumber}
                                        onChange={handleInputChange}
                                        style={{
                                            width: '100%',
                                            padding: '10px',
                                            borderRadius: '4px',
                                            border: '1px solid #ccc',
                                            fontSize: '14px'
                                        }}
                                    />
                                </div>
                            </div>
                            <div style={{ display: 'flex', gap: '10px', marginTop: '20px' }}>
                                <button
                                    type="submit"
                                    disabled={loading}
                                    style={{
                                        padding: '10px 20px',
                                        backgroundColor: loading ? '#ccc' : '#4caf50',
                                        color: 'white',
                                        border: 'none',
                                        borderRadius: '4px',
                                        cursor: loading ? 'not-allowed' : 'pointer'
                                    }}
                                >
                                    {loading ? '⏳ Đang lưu...' : '💾 Lưu thay đổi'}
                                </button>
                                <button
                                    type="button"
                                    onClick={handleCancelEdit}
                                    style={{
                                        padding: '10px 20px',
                                        backgroundColor: '#f44336',
                                        color: 'white',
                                        border: 'none',
                                        borderRadius: '4px',
                                        cursor: 'pointer'
                                    }}
                                >
                                    ❌ Hủy
                                </button>
                            </div>
                        </form>
                    ) : (
                        <div style={{ display: 'grid', gap: '15px' }}>
                            <div style={{ display: 'flex', justifyContent: 'space-between', padding: '12px 0', borderBottom: '1px solid #f0f0f0' }}>
                                <span style={{ fontWeight: '500', color: '#666' }}>Họ và tên:</span>
                                <span style={{ fontWeight: '600' }}>{customerInfo.fullName || '-'}</span>
                            </div>
                            <div style={{ display: 'flex', justifyContent: 'space-between', padding: '12px 0', borderBottom: '1px solid #f0f0f0' }}>
                                <span style={{ fontWeight: '500', color: '#666' }}>Email:</span>
                                <span style={{ fontWeight: '600' }}>{customerInfo.email || '-'}</span>
                            </div>
                            <div style={{ display: 'flex', justifyContent: 'space-between', padding: '12px 0', borderBottom: '1px solid #f0f0f0' }}>
                                <span style={{ fontWeight: '500', color: '#666' }}>Số điện thoại:</span>
                                <span style={{ fontWeight: '600' }}>{customerInfo.phone || '-'}</span>
                            </div>
                            <div style={{ display: 'flex', justifyContent: 'space-between', padding: '12px 0', borderBottom: '1px solid #f0f0f0' }}>
                                <span style={{ fontWeight: '500', color: '#666' }}>Địa chỉ:</span>
                                <span style={{ fontWeight: '600', textAlign: 'right', maxWidth: '200px' }}>
                                    {customerInfo.address || '-'}
                                </span>
                            </div>
                            <div style={{ display: 'flex', justifyContent: 'space-between', padding: '12px 0', borderBottom: '1px solid #f0f0f0' }}>
                                <span style={{ fontWeight: '500', color: '#666' }}>Ngày sinh:</span>
                                <span style={{ fontWeight: '600' }}>{formatDate(customerInfo.dateOfBirth || '')}</span>
                            </div>
                            <div style={{ display: 'flex', justifyContent: 'space-between', padding: '12px 0', borderBottom: '1px solid #f0f0f0' }}>
                                <span style={{ fontWeight: '500', color: '#666' }}>Số CMND/CCCD:</span>
                                <span style={{ fontWeight: '600' }}>{customerInfo.idNumber || '-'}</span>
                            </div>
                            <div style={{ display: 'flex', justifyContent: 'space-between', padding: '12px 0' }}>
                                <span style={{ fontWeight: '500', color: '#666' }}>Ngày tạo tài khoản:</span>
                                <span style={{ fontWeight: '600' }}>{formatDate(customerInfo.createdAt || '')}</span>
                            </div>
                        </div>
                    )}
                </div>

                {/* Danh sách tài khoản */}
                <div style={{
                    backgroundColor: 'white',
                    padding: '25px',
                    borderRadius: '8px',
                    boxShadow: '0 4px 6px rgba(0,0,0,0.1)',
                    border: '1px solid #e0e0e0'
                }}>
                    <h3 style={{
                        margin: '0 0 20px 0',
                        color: '#1976d2',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'space-between',
                        paddingBottom: '15px',
                        borderBottom: '2px solid #e0e0e0'
                    }}>
                        <span style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                            🏦 Tài khoản của tôi
                        </span>
                        <span style={{
                            backgroundColor: '#e3f2fd',
                            color: '#1976d2',
                            padding: '4px 12px',
                            borderRadius: '12px',
                            fontSize: '14px',
                            fontWeight: 'bold'
                        }}>
                            {accounts.length} tài khoản
                        </span>
                    </h3>

                    {accounts.length === 0 ? (
                        <div style={{
                            textAlign: 'center',
                            padding: '40px',
                            backgroundColor: '#f9f9f9',
                            borderRadius: '8px',
                            border: '2px dashed #e0e0e0'
                        }}>
                            <div style={{ fontSize: '48px', marginBottom: '15px' }}>🏦</div>
                            <p style={{ color: '#666', margin: '0 0 15px 0', fontSize: '16px' }}>
                                Bạn chưa có tài khoản nào
                            </p>
                            <button
                                onClick={() => navigate('/create-account')}
                                style={{
                                    padding: '10px 20px',
                                    backgroundColor: '#4caf50',
                                    color: 'white',
                                    border: 'none',
                                    borderRadius: '4px',
                                    cursor: 'pointer',
                                    fontSize: '14px'
                                }}
                            >
                                ➕ Tạo tài khoản đầu tiên
                            </button>
                        </div>
                    ) : (
                        <div style={{ display: 'grid', gap: '15px' }}>
                            {accounts.map((account) => (
                                <div key={account.id} style={{
                                    padding: '20px',
                                    border: '1px solid #e0e0e0',
                                    borderRadius: '8px',
                                    backgroundColor: '#fafafa',
                                    transition: 'all 0.2s ease'
                                }}>
                                    <div style={{
                                        display: 'flex',
                                        justifyContent: 'space-between',
                                        alignItems: 'center',
                                        marginBottom: '15px'
                                    }}>
                                        <div style={{
                                            display: 'flex',
                                            alignItems: 'center',
                                            gap: '10px'
                                        }}>
                                            <span style={{ fontSize: '24px' }}>
                                                {getAccountTypeIcon(account.accountType)}
                                            </span>
                                            <div>
                                                <div style={{ fontWeight: '600', fontSize: '16px' }}>
                                                    {getAccountTypeName(account.accountType)}
                                                </div>
                                                <div style={{
                                                    fontSize: '14px',
                                                    color: '#666',
                                                    fontFamily: 'Consolas, monospace'
                                                }}>
                                                    {account.accountNumber}
                                                </div>
                                            </div>
                                        </div>
                                        <div style={{ textAlign: 'right' }}>
                                            <div style={{
                                                fontSize: '18px',
                                                fontWeight: '700',
                                                color: account.balance >= 0 ? '#4caf50' : '#f44336'
                                            }}>
                                                {formatCurrency(account.balance)}
                                            </div>
                                            <div style={{
                                                fontSize: '12px',
                                                color: getStatusColor(account.status),
                                                fontWeight: '500'
                                            }}>
                                                {getStatusText(account.status)}
                                            </div>
                                        </div>
                                    </div>
                                    <div style={{ fontSize: '12px', color: '#999' }}>
                                        Ngày mở: {formatDate(account.openDate)}
                                    </div>
                                </div>
                            ))}
                        </div>
                    )}

                    {/* Quick Actions */}
                    <div style={{
                        marginTop: '25px',
                        paddingTop: '20px',
                        borderTop: '1px solid #e0e0e0',
                        display: 'grid',
                        gridTemplateColumns: '1fr 1fr',
                        gap: '15px'
                    }}>
                        <button
                            onClick={() => navigate('/create-account')}
                            style={{
                                padding: '12px',
                                backgroundColor: '#4caf50',
                                color: 'white',
                                border: 'none',
                                borderRadius: '4px',
                                cursor: 'pointer',
                                fontSize: '14px',
                                display: 'flex',
                                alignItems: 'center',
                                justifyContent: 'center',
                                gap: '8px'
                            }}
                        >
                            ➕ Tạo tài khoản mới
                        </button>
                        <button
                            onClick={() => navigate('/transfer')}
                            style={{
                                padding: '12px',
                                backgroundColor: '#2196f3',
                                color: 'white',
                                border: 'none',
                                borderRadius: '4px',
                                cursor: 'pointer',
                                fontSize: '14px',
                                display: 'flex',
                                alignItems: 'center',
                                justifyContent: 'center',
                                gap: '8px'
                            }}
                        >
                            💸 Chuyển tiền
                        </button>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default CustomerInfoPage;
