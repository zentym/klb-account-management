import React, { useState, useEffect } from 'react';
import './PhoneDashboard.css';
import bankingApiService from '../services/bankingApiService';
import customKeycloakService from '../services/customKeycloakService';

interface User {
    phoneNumber: string;
    fullName?: string;
    email?: string;
    registeredAt?: string;
    loginAt?: string;
    rememberMe?: boolean;
    otpVerified?: boolean;
    username?: string;
    token?: string;
    roles?: string[];
}

interface Account {
    id: string;
    accountNumber: string;
    accountType: string;
    balance: number;
    currency: string;
    status: string;
}

interface Transaction {
    id: string;
    accountNumber: string;
    amount: number;
    type: 'DEBIT' | 'CREDIT';
    description: string;
    timestamp: string;
    balance?: number;
}

interface Customer {
    id: string;
    firstName: string;
    lastName: string;
    email: string;
    phoneNumber: string;
    address?: string;
}

interface PhoneDashboardProps {
    user: User;
    onLogout?: () => void;
}

export const PhoneDashboard: React.FC<PhoneDashboardProps> = ({ user, onLogout }) => {
    const [accounts, setAccounts] = useState<Account[]>([]);
    const [transactions, setTransactions] = useState<Transaction[]>([]);
    const [customerInfo, setCustomerInfo] = useState<Customer | null>(null);
    const [loading, setLoading] = useState<boolean>(true);
    const [error, setError] = useState<string>('');
    const [isOnline, setIsOnline] = useState<boolean>(false);

    // Load real data from APIs
    useEffect(() => {
        loadDashboardData();
    }, []);

    const loadDashboardData = async () => {
        setLoading(true);
        setError('');

        try {
            // Check if backend is available
            const healthCheck = await bankingApiService.healthCheck();
            setIsOnline(healthCheck);

            if (healthCheck && customKeycloakService.isAuthenticated()) {
                console.log('🔄 Loading real banking data...');

                // Load data in parallel
                const [accountsData, transactionsData, customerData] = await Promise.allSettled([
                    bankingApiService.getAccounts(),
                    bankingApiService.getTransactions(undefined, 5),
                    bankingApiService.getCustomerInfo()
                ]);

                // Handle accounts
                if (accountsData.status === 'fulfilled') {
                    setAccounts(accountsData.value);
                    console.log('✅ Accounts loaded:', accountsData.value);
                } else {
                    console.warn('⚠️ Failed to load accounts:', accountsData.reason);
                }

                // Handle transactions
                if (transactionsData.status === 'fulfilled') {
                    setTransactions(transactionsData.value);
                    console.log('✅ Transactions loaded:', transactionsData.value);
                } else {
                    console.warn('⚠️ Failed to load transactions:', transactionsData.reason);
                }

                // Handle customer info
                if (customerData.status === 'fulfilled') {
                    setCustomerInfo(customerData.value);
                    console.log('✅ Customer info loaded:', customerData.value);
                } else {
                    console.warn('⚠️ Failed to load customer info:', customerData.reason);
                }

            } else {
                console.log('🔄 Using demo data - backend unavailable or user not authenticated');
                setError('Đang sử dụng dữ liệu demo - Backend không khả dụng');
            }

        } catch (err: any) {
            console.error('❌ Error loading dashboard data:', err);
            setError('Có lỗi khi tải dữ liệu. Sử dụng dữ liệu demo.');
            setIsOnline(false);
        } finally {
            setLoading(false);
        }
    };

    const formatCurrency = (amount: number): string => {
        return new Intl.NumberFormat('vi-VN', {
            style: 'currency',
            currency: 'VND'
        }).format(amount);
    };

    const formatDate = (dateString: string): string => {
        return new Date(dateString).toLocaleString('vi-VN');
    };

    // Get account balance (from real data or fallback to demo)
    const accountBalance = accounts.length > 0
        ? accounts.reduce((total, account) => total + account.balance, 0)
        : 15750000; // fallback demo data

    // Get recent transactions (real or demo)
    const recentTransactions = transactions.length > 0
        ? transactions.slice(0, 3).map(t => ({
            id: parseInt(t.id) || Math.random(),
            type: t.type === 'CREDIT' ? 'receive' : 'send',
            amount: t.type === 'CREDIT' ? t.amount : -t.amount,
            description: t.description,
            date: t.timestamp
        }))
        : [
            { id: 1, type: 'receive', amount: 2500000, description: 'Chuyển khoản từ Nguyễn Văn B', date: new Date().toISOString() },
            { id: 2, type: 'send', amount: -500000, description: 'Thanh toán hóa đơn điện', date: new Date(Date.now() - 86400000).toISOString() },
            { id: 3, type: 'receive', amount: 1200000, description: 'Lương tháng 8', date: new Date(Date.now() - 172800000).toISOString() },
        ];

    // Get user display name (from real data or fallback)
    const displayName = customerInfo
        ? `${customerInfo.firstName} ${customerInfo.lastName}`.trim()
        : user.fullName || user.username || user.phoneNumber;

    const displayEmail = customerInfo?.email || user.email || `${user.phoneNumber}@klb-demo.com`;

    const quickActions = [
        { icon: '💸', title: 'Chuyển tiền', color: '#3b82f6' },
        { icon: '📱', title: 'Nạp thẻ', color: '#10b981' },
        { icon: '💡', title: 'Thanh toán', color: '#f59e0b' },
        { icon: '💰', title: 'Tiết kiệm', color: '#8b5cf6' },
        { icon: '🏦', title: 'Vay vốn', color: '#ef4444' },
        { icon: '📊', title: 'Báo cáo', color: '#6b7280' },
    ];

    return (
        <div className="phone-dashboard-container">
            {/* Header */}
            <div className="phone-dashboard-header">
                <div className="header-content">
                    <div className="user-greeting">
                        <div className="user-avatar">
                            {user.fullName ? user.fullName.charAt(0).toUpperCase() : '👤'}
                        </div>
                        <div className="greeting-text">
                            <h2>Chào {displayName}!</h2>
                            <p>
                                {isOnline ? '🟢 Kết nối thực tế' : '🟡 Chế độ demo'}
                                {loading && ' - Đang tải...'}
                            </p>
                        </div>
                    </div>

                    <div className="header-actions">
                        <button className="notification-btn">
                            🔔
                            <span className="notification-badge">3</span>
                        </button>
                        <button className="logout-btn" onClick={onLogout}>
                            Đăng xuất
                        </button>
                    </div>
                </div>
            </div>

            {/* Status Banner */}
            {error && (
                <div className="status-banner warning">
                    <span>⚠️ {error}</span>
                    <button onClick={loadDashboardData}>🔄 Thử lại</button>
                </div>
            )}

            {/* Account Balance Card */}
            <div className="balance-card">
                <div className="balance-header">
                    <h3>Số dư tài khoản</h3>
                    <div className="account-info">
                        <span className="account-number">**** **** {user.phoneNumber.slice(-4)}</span>
                        <span className="account-type">Tài khoản thanh toán</span>
                    </div>
                </div>
                <div className="balance-amount">
                    <span className="amount">{formatCurrency(accountBalance)}</span>
                    <button className="toggle-balance">👁️</button>
                </div>
                <div className="balance-actions">
                    <button className="balance-action-btn primary">
                        <span className="action-icon">💸</span>
                        Chuyển tiền
                    </button>
                    <button className="balance-action-btn">
                        <span className="action-icon">📥</span>
                        Nạp tiền
                    </button>
                    <button className="balance-action-btn">
                        <span className="action-icon">📊</span>
                        Lịch sử
                    </button>
                </div>
            </div>

            <div className="dashboard-content">
                {/* Quick Actions */}
                <div className="quick-actions-section">
                    <h3 className="section-title">Dịch vụ nhanh</h3>
                    <div className="quick-actions-grid">
                        {quickActions.map((action, index) => (
                            <button
                                key={index}
                                className="quick-action-item"
                                style={{ borderTop: `3px solid ${action.color}` }}
                            >
                                <div className="quick-action-icon">{action.icon}</div>
                                <span className="quick-action-title">{action.title}</span>
                            </button>
                        ))}
                    </div>
                </div>

                {/* Recent Transactions */}
                <div className="transactions-section">
                    <div className="section-header">
                        <h3 className="section-title">Giao dịch gần đây</h3>
                        <button className="view-all-btn">Xem tất cả</button>
                    </div>

                    <div className="transactions-list">
                        {recentTransactions.map((transaction) => (
                            <div key={transaction.id} className="transaction-item">
                                <div className="transaction-icon">
                                    {transaction.type === 'receive' ? '📥' : '📤'}
                                </div>
                                <div className="transaction-details">
                                    <div className="transaction-description">
                                        {transaction.description}
                                    </div>
                                    <div className="transaction-date">
                                        {formatDate(transaction.date)}
                                    </div>
                                </div>
                                <div className={`transaction-amount ${transaction.type}`}>
                                    {transaction.type === 'receive' ? '+' : ''}{formatCurrency(transaction.amount)}
                                </div>
                            </div>
                        ))}
                    </div>
                </div>

                {/* User Profile Info */}
                <div className="profile-section">
                    <h3 className="section-title">Thông tin tài khoản</h3>
                    <div className="profile-card">
                        <div className="profile-item">
                            <span className="profile-label">Số điện thoại:</span>
                            <span className="profile-value">{user.phoneNumber}</span>
                        </div>
                        {user.fullName && (
                            <div className="profile-item">
                                <span className="profile-label">Họ và tên:</span>
                                <span className="profile-value">{user.fullName}</span>
                            </div>
                        )}
                        {user.email && (
                            <div className="profile-item">
                                <span className="profile-label">Email:</span>
                                <span className="profile-value">{user.email}</span>
                            </div>
                        )}
                        <div className="profile-item">
                            <span className="profile-label">Đăng nhập lần cuối:</span>
                            <span className="profile-value">
                                {user.loginAt ? formatDate(user.loginAt) : 'N/A'}
                                {user.otpVerified && <span className="verified-badge">🔐 Đã xác thực</span>}
                            </span>
                        </div>
                        {user.registeredAt && (
                            <div className="profile-item">
                                <span className="profile-label">Ngày đăng ký:</span>
                                <span className="profile-value">{formatDate(user.registeredAt)}</span>
                            </div>
                        )}
                    </div>
                </div>
            </div>

            {/* Bottom Navigation */}
            <div className="bottom-nav">
                <button className="nav-item active">
                    <span className="nav-icon">🏠</span>
                    <span className="nav-label">Trang chủ</span>
                </button>
                <button className="nav-item">
                    <span className="nav-icon">💸</span>
                    <span className="nav-label">Chuyển tiền</span>
                </button>
                <button className="nav-item">
                    <span className="nav-icon">📊</span>
                    <span className="nav-label">Lịch sử</span>
                </button>
                <button className="nav-item">
                    <span className="nav-icon">⚙️</span>
                    <span className="nav-label">Cài đặt</span>
                </button>
            </div>
        </div>
    );
};

export default PhoneDashboard;
