import React, { useState } from 'react';
import { BrowserRouter as Router, Routes, Route, useNavigate, useLocation } from 'react-router-dom';
import AuthFlow from './components/AuthFlow';
import Dashboard from './components/Dashboard';
import TransferPage from './components/TransferPage';
import { TransactionHistory } from './components/TransactionHistory';
import CustomerInfoPage from './components/CustomerInfoPage';
import { LoanApplicationPage } from './components/LoanApplicationPage';
import MyLoansPage from './components/MyLoansPage';
import CreateAccountPage from './components/CreateAccountPage';
import './App.css';

interface User {
    phoneNumber: string;
    fullName?: string;
    email?: string;
    registeredAt?: string;
    loginAt?: string;
    rememberMe?: boolean;
    otpVerified?: boolean;
}

// Mock account data for transaction history
const mockAccount = {
    id: 1,
    accountNumber: '1234567890',
    accountType: 'SAVINGS',
    balance: 15750000,
    status: 'ACTIVE',
    openDate: new Date().toISOString()
};

// Enhanced Dashboard with routing
const EnhancedDashboard: React.FC<{ user: User; onLogout: () => void }> = ({ user, onLogout }) => {
    const navigate = useNavigate();
    const location = useLocation();
    const [showTransactionHistory, setShowTransactionHistory] = useState(false);

    // Navigation handlers
    const handleNavigation = (path: string) => {
        navigate(path);
    };

    const isCurrentPath = (path: string) => location.pathname === path;

    // Enhanced Dashboard with navigation
    const EnhancedDashboard: React.FC = () => {
        return (
            <div className="enhanced-dashboard">
                <Dashboard />

                {/* Custom navigation overlay for quick actions */}
                <div className="quick-nav-overlay">
                    <button
                        className="enhanced-quick-btn transfer-btn"
                        onClick={() => handleNavigation('/transfer')}
                    >
                        <span className="btn-icon">💸</span>
                        <span className="btn-text">Chuyển tiền</span>
                    </button>

                    <button
                        className="enhanced-quick-btn history-btn"
                        onClick={() => setShowTransactionHistory(true)}
                    >
                        <span className="btn-icon">📊</span>
                        <span className="btn-text">Lịch sử</span>
                    </button>

                    <button
                        className="enhanced-quick-btn profile-btn"
                        onClick={() => handleNavigation('/profile')}
                    >
                        <span className="btn-icon">👤</span>
                        <span className="btn-text">Hồ sơ</span>
                    </button>

                    <button
                        className="enhanced-quick-btn loan-btn"
                        onClick={() => handleNavigation('/loans')}
                    >
                        <span className="btn-icon">🏦</span>
                        <span className="btn-text">Vay vốn</span>
                    </button>
                </div>

                {/* Transaction History Modal */}
                {showTransactionHistory && (
                    <div className="modal-overlay">
                        <div className="modal-content">
                            <TransactionHistory
                                account={mockAccount}
                                onClose={() => setShowTransactionHistory(false)}
                            />
                        </div>
                    </div>
                )}
            </div>
        );
    };

    // Page Header Component
    const PageHeader: React.FC<{ title: string; showBackButton?: boolean }> = ({ title, showBackButton = true }) => {
        return (
            <div className="page-header">
                <div className="header-content">
                    {showBackButton && (
                        <button className="back-btn" onClick={() => navigate('/')}>
                            ← Quay lại
                        </button>
                    )}
                    <h1 className="page-title">{title}</h1>
                    <div className="user-info">
                        <span className="user-name">{user.fullName || 'Khách hàng'}</span>
                        <button className="logout-btn" onClick={onLogout}>Đăng xuất</button>
                    </div>
                </div>
            </div>
        );
    };

    return (
        <div className="enhanced-dashboard-container">
            <Routes>
                {/* Main Dashboard */}
                <Route path="/" element={<EnhancedDashboard />} />

                {/* Transfer Page */}
                <Route
                    path="/transfer"
                    element={
                        <div className="page-container">
                            <PageHeader title="Chuyển tiền" />
                            <div className="page-content">
                                <TransferPage />
                            </div>
                        </div>
                    }
                />

                {/* Customer Info Page */}
                <Route
                    path="/profile"
                    element={
                        <div className="page-container">
                            <PageHeader title="Thông tin cá nhân" />
                            <div className="page-content">
                                <CustomerInfoPage />
                            </div>
                        </div>
                    }
                />

                {/* Loan Application Page */}
                <Route
                    path="/loan-apply"
                    element={
                        <div className="page-container">
                            <PageHeader title="Đăng ký vay vốn" />
                            <div className="page-content">
                                <LoanApplicationPage />
                            </div>
                        </div>
                    }
                />

                {/* My Loans Page */}
                <Route
                    path="/loans"
                    element={
                        <div className="page-container">
                            <PageHeader title="Khoản vay của tôi" />
                            <div className="page-content">
                                <MyLoansPage />
                            </div>
                        </div>
                    }
                />

                {/* Create Account Page */}
                <Route
                    path="/create-account"
                    element={
                        <div className="page-container">
                            <PageHeader title="Mở tài khoản mới" />
                            <div className="page-content">
                                <CreateAccountPage />
                            </div>
                        </div>
                    }
                />

                {/* Fallback to dashboard */}
                <Route path="*" element={<EnhancedDashboard />} />
            </Routes>

            {/* Bottom Navigation */}
            <div className="enhanced-bottom-nav">
                <button
                    className={`nav-item ${isCurrentPath('/') ? 'active' : ''}`}
                    onClick={() => handleNavigation('/')}
                >
                    <span className="nav-icon">🏠</span>
                    <span className="nav-label">Trang chủ</span>
                </button>
                <button
                    className={`nav-item ${isCurrentPath('/transfer') ? 'active' : ''}`}
                    onClick={() => handleNavigation('/transfer')}
                >
                    <span className="nav-icon">💸</span>
                    <span className="nav-label">Chuyển tiền</span>
                </button>
                <button
                    className={`nav-item ${isCurrentPath('/profile') ? 'active' : ''}`}
                    onClick={() => handleNavigation('/profile')}
                >
                    <span className="nav-icon">👤</span>
                    <span className="nav-label">Hồ sơ</span>
                </button>
                <button
                    className={`nav-item ${isCurrentPath('/loans') ? 'active' : ''}`}
                    onClick={() => handleNavigation('/loans')}
                >
                    <span className="nav-icon">🏦</span>
                    <span className="nav-label">Vay vốn</span>
                </button>
            </div>

            <style>
                {`
                .enhanced-dashboard-container {
                    min-height: 100vh;
                    background: #f8fafc;
                }

                .quick-nav-overlay {
                    position: fixed;
                    bottom: 100px;
                    right: 20px;
                    display: flex;
                    flex-direction: column;
                    gap: 12px;
                    z-index: 1000;
                }

                .enhanced-quick-btn {
                    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                    border: none;
                    border-radius: 50px;
                    color: white;
                    padding: 12px 20px;
                    display: flex;
                    align-items: center;
                    gap: 8px;
                    font-weight: 600;
                    cursor: pointer;
                    transition: all 0.3s ease;
                    box-shadow: 0 4px 12px rgba(102, 126, 234, 0.3);
                }

                .enhanced-quick-btn:hover {
                    transform: translateY(-2px);
                    box-shadow: 0 6px 20px rgba(102, 126, 234, 0.4);
                }

                .btn-icon {
                    font-size: 16px;
                }

                .btn-text {
                    font-size: 14px;
                }

                .modal-overlay {
                    position: fixed;
                    top: 0;
                    left: 0;
                    right: 0;
                    bottom: 0;
                    background: rgba(0, 0, 0, 0.5);
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    z-index: 2000;
                    padding: 20px;
                }

                .modal-content {
                    background: white;
                    border-radius: 12px;
                    max-width: 90vw;
                    max-height: 90vh;
                    overflow: auto;
                    box-shadow: 0 20px 40px rgba(0, 0, 0, 0.1);
                }

                .page-container {
                    min-height: 100vh;
                    background: #f8fafc;
                }

                .page-header {
                    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                    padding: 20px;
                    color: white;
                    position: sticky;
                    top: 0;
                    z-index: 100;
                }

                .header-content {
                    display: flex;
                    align-items: center;
                    justify-content: space-between;
                    max-width: 1200px;
                    margin: 0 auto;
                }

                .back-btn {
                    background: rgba(255, 255, 255, 0.2);
                    border: none;
                    color: white;
                    padding: 8px 16px;
                    border-radius: 8px;
                    cursor: pointer;
                    font-size: 14px;
                    transition: all 0.3s ease;
                }

                .back-btn:hover {
                    background: rgba(255, 255, 255, 0.3);
                }

                .page-title {
                    font-size: 20px;
                    font-weight: 600;
                    margin: 0;
                }

                .user-info {
                    display: flex;
                    align-items: center;
                    gap: 12px;
                }

                .user-name {
                    font-size: 14px;
                    opacity: 0.9;
                }

                .logout-btn {
                    background: rgba(255, 255, 255, 0.2);
                    border: 1px solid rgba(255, 255, 255, 0.3);
                    color: white;
                    padding: 6px 12px;
                    border-radius: 6px;
                    font-size: 12px;
                    cursor: pointer;
                    transition: all 0.3s ease;
                }

                .logout-btn:hover {
                    background: rgba(255, 255, 255, 0.3);
                }

                .page-content {
                    padding: 20px;
                    max-width: 1200px;
                    margin: 0 auto;
                    padding-bottom: 100px;
                }

                .enhanced-bottom-nav {
                    position: fixed;
                    bottom: 0;
                    left: 0;
                    right: 0;
                    background: white;
                    border-top: 1px solid #e5e7eb;
                    padding: 8px 0;
                    display: flex;
                    z-index: 1000;
                    box-shadow: 0 -2px 10px rgba(0, 0, 0, 0.1);
                }

                .nav-item {
                    flex: 1;
                    background: none;
                    border: none;
                    padding: 8px 4px;
                    display: flex;
                    flex-direction: column;
                    align-items: center;
                    gap: 4px;
                    cursor: pointer;
                    transition: all 0.3s ease;
                    color: #6b7280;
                }

                .nav-item.active {
                    color: #667eea;
                }

                .nav-item:hover {
                    color: #667eea;
                    background: rgba(102, 126, 234, 0.05);
                }

                .nav-icon {
                    font-size: 20px;
                }

                .nav-label {
                    font-size: 10px;
                    font-weight: 500;
                }

                @media (max-width: 640px) {
                    .header-content {
                        padding: 0 16px;
                    }
                    
                    .page-content {
                        padding: 16px;
                    }
                    
                    .quick-nav-overlay {
                        right: 16px;
                        bottom: 90px;
                    }
                    
                    .enhanced-quick-btn {
                        padding: 10px 16px;
                    }
                    
                    .btn-text {
                        font-size: 12px;
                    }
                }
                `}
            </style>
        </div>
    );
};

function EnhancedPhoneBankingApp() {
    const [currentUser, setCurrentUser] = useState<User | null>(null);
    const [isAuthenticated, setIsAuthenticated] = useState<boolean>(false);

    const handleAuthSuccess = (user: User, type: 'login' | 'register') => {
        console.log(`${type} successful:`, user);
        setCurrentUser(user);
        setIsAuthenticated(true);
    };

    const handleLogout = () => {
        setCurrentUser(null);
        setIsAuthenticated(false);
        console.log('User logged out');
    };

    return (
        <div className="enhanced-phone-banking-app">
            {isAuthenticated && currentUser ? (
                <Router>
                    <EnhancedDashboard
                        user={currentUser}
                        onLogout={handleLogout}
                    />
                </Router>
            ) : (
                <AuthFlow
                    onAuthSuccess={handleAuthSuccess}
                />
            )}
        </div>
    );
}

export default EnhancedPhoneBankingApp;
