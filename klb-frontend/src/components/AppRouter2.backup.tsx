import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate, useNavigate } from 'react-router-dom';
import { useAuth } from './AuthProvider';
import ProtectedRoute from './ProtectedRoute';
import Layout from './Layout';
import { LoginPage } from './LoginPage';
import { RegisterPage } from './RegisterPage';
import { CustomerPage } from './CustomerPage';
import TransferPage from './TransferPage';
import { RoleBasedExample } from './RoleBasedExample';
import { TransactionHistory } from './TransactionHistory';

// Component wrapper cho Login với navigation
const LoginPageWithNavigation: React.FC = () => {
    const navigate = useNavigate();

    return (
        <>
            <LoginPage onSwitchToRegister={() => navigate('/register')} />
            <div style={{ textAlign: 'center', marginTop: '20px' }}>
                <button
                    onClick={() => navigate('/register')}
                    style={{
                        background: 'none',
                        border: 'none',
                        color: '#1976d2',
                        textDecoration: 'underline',
                        cursor: 'pointer'
                    }}
                >
                    Chưa có tài khoản? Đăng ký ngay
                </button>
            </div>
        </>
    );
};

// Component wrapper cho Register với navigation
const RegisterPageWithNavigation: React.FC = () => {
    const navigate = useNavigate();

    return (
        <>
            <RegisterPage onSwitchToLogin={() => navigate('/login')} />
            <div style={{ textAlign: 'center', marginTop: '20px' }}>
                <button
                    onClick={() => navigate('/login')}
                    style={{
                        background: 'none',
                        border: 'none',
                        color: '#1976d2',
                        textDecoration: 'underline',
                        cursor: 'pointer'
                    }}
                >
                    Đã có tài khoản? Đăng nhập
                </button>
            </div>
        </>
    );
};

// Component wrapper cho TransactionHistory
const TransactionHistoryPage: React.FC = () => {
    const navigate = useNavigate();
    // Tạo account mặc định hoặc lấy từ context/state
    const defaultAccount = {
        accountNumber: '',
        accountType: 'CHECKING',
        balance: 0,
        status: 'ACTIVE',
        openDate: new Date().toISOString()
    };

    return (
        <div style={{ padding: '20px' }}>
            <h2>📊 Lịch sử giao dịch</h2>
            <TransactionHistory
                account={defaultAccount}
                onClose={() => navigate('/dashboard')}
            />
        </div>
    );
};

// Component Authentication Layout cho login/register
const AuthLayout: React.FC<{ children: React.ReactNode }> = ({ children }) => {
    return (
        <div style={{
            maxWidth: '400px',
            margin: '0 auto',
            padding: '20px'
        }}>
            {children}
        </div>
    );
};

// Component trang chủ dashboard
const Dashboard: React.FC = () => {
    return (
        <div>
            <CustomerPage />
            <TransferPage />
            <RoleBasedExample />
        </div>
    );
};

// Component chính để định tuyến
export const AppRouter: React.FC = () => {
    const { isAuthenticated } = useAuth();

    return (
        <Router>
            <Routes>
                {/* Public Routes */}
                <Route
                    path="/login"
                    element={
                        !isAuthenticated ? (
                            <Layout>
                                <AuthLayout>
                                    <LoginPageWithNavigation />
                                </AuthLayout>
                            </Layout>
                        ) : (
                            <Navigate to="/dashboard" replace />
                        )
                    }
                />

                <Route
                    path="/register"
                    element={
                        !isAuthenticated ? (
                            <Layout>
                                <AuthLayout>
                                    <RegisterPageWithNavigation />
                                </AuthLayout>
                            </Layout>
                        ) : (
                            <Navigate to="/dashboard" replace />
                        )
                    }
                />

                {/* Protected Routes */}
                <Route
                    path="/dashboard"
                    element={
                        <Layout>
                            <ProtectedRoute>
                                <Dashboard />
                            </ProtectedRoute>
                        </Layout>
                    }
                />

                <Route
                    path="/customers"
                    element={
                        <Layout>
                            <ProtectedRoute requiredRoles={['ADMIN']}>
                                <CustomerPage />
                            </ProtectedRoute>
                        </Layout>
                    }
                />

                <Route
                    path="/transfer"
                    element={
                        <Layout>
                            <ProtectedRoute requiredRoles={['ADMIN']}>
                                <TransferPage />
                            </ProtectedRoute>
                        </Layout>
                    }
                />

                <Route
                    path="/transactions"
                    element={
                        <Layout>
                            <ProtectedRoute requiredRoles={['USER', 'ADMIN']}>
                                <TransactionHistoryPage />
                            </ProtectedRoute>
                        </Layout>
                    }
                />

                <Route
                    path="/admin"
                    element={
                        <Layout>
                            <ProtectedRoute requiredRoles={['ADMIN']}>
                                <RoleBasedExample />
                            </ProtectedRoute>
                        </Layout>
                    }
                />

                {/* Default redirects */}
                <Route
                    path="/"
                    element={
                        isAuthenticated ?
                            <Navigate to="/dashboard" replace /> :
                            <Navigate to="/login" replace />
                    }
                />

                {/* 404 Not Found */}
                <Route
                    path="*"
                    element={
                        <Layout>
                            <div style={{
                                textAlign: 'center',
                                padding: '40px',
                                color: '#666'
                            }}>
                                <h2>404 - Trang không tìm thấy</h2>
                                <p>Trang bạn đang tìm kiếm không tồn tại.</p>
                                <button
                                    onClick={() => window.location.href = isAuthenticated ? '/dashboard' : '/login'}
                                    style={{
                                        padding: '10px 20px',
                                        backgroundColor: '#1976d2',
                                        color: 'white',
                                        border: 'none',
                                        borderRadius: '4px',
                                        cursor: 'pointer',
                                        marginTop: '15px'
                                    }}
                                >
                                    {isAuthenticated ? 'Về trang chủ' : 'Đăng nhập'}
                                </button>
                            </div>
                        </Layout>
                    }
                />
            </Routes>
        </Router>
    );
};

export default AppRouter;
