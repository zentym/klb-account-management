import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate, useNavigate } from 'react-router-dom';
import useCustomAuth from '../hooks/useCustomAuth';
import CustomProtectedRoute from './CustomProtectedRoute';
import Layout from './Layout';
import { LoginPage } from './LoginPage';
import CustomLoginPage from './CustomLoginPage';
import { RegisterPage } from './RegisterPage';
import { CustomerPage } from './CustomerPage';
import TransferPage from './TransferPage';
import { RoleBasedExample } from './RoleBasedExample';
import { TransactionHistory } from './TransactionHistory';
import AuthCallback from './AuthCallback';
import LoanApplicationPage from './LoanApplicationPage';
import MyLoansPage from './MyLoansPage';
import Dashboard from './Dashboard';
import CreateAccountPage from './CreateAccountPage';
import CustomerInfoPage from './CustomerInfoPage';

// Component wrapper cho Login với navigation
const LoginPageWithNavigation: React.FC = () => {
    const navigate = useNavigate();

    return (
        <>
            <LoginPage
                onSwitchToRegister={() => navigate('/register')}
            />
            <div style={{ textAlign: 'center', marginTop: '20px' }}>
                <p style={{ color: '#666' }}>
                    Need an account? Contact your administrator for access.
                </p>
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
const DashboardComponent: React.FC = () => {
    return (
        <Dashboard />
    );
};

// Component chính để định tuyến
export const AppRouter: React.FC = () => {
    const { isAuthenticated } = useCustomAuth();

    return (
        <Router>
            <Routes>
                {/* Keycloak callback route */}
                <Route path="/callback" element={<AuthCallback />} />

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

                {/* Custom Login Route for Direct API */}
                <Route
                    path="/custom-login"
                    element={
                        !isAuthenticated ? (
                            <Layout>
                                <AuthLayout>
                                    <CustomLoginPage />
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
                            <CustomProtectedRoute>
                                <DashboardComponent />
                            </CustomProtectedRoute>
                        </Layout>
                    }
                />

                <Route
                    path="/customers"
                    element={
                        <Layout>
                            <CustomProtectedRoute requiredRoles={['ADMIN']}>
                                <CustomerPage />
                            </CustomProtectedRoute>
                        </Layout>
                    }
                />

                <Route
                    path="/create-account"
                    element={
                        <Layout>
                            <CustomProtectedRoute requiredRoles={['USER', 'ADMIN']}>
                                <CreateAccountPage />
                            </CustomProtectedRoute>
                        </Layout>
                    }
                />

                <Route
                    path="/customer-info"
                    element={
                        <Layout>
                            <CustomProtectedRoute requiredRoles={['USER', 'ADMIN']}>
                                <CustomerInfoPage />
                            </CustomProtectedRoute>
                        </Layout>
                    }
                />

                <Route
                    path="/transfer"
                    element={
                        <Layout>
                            <CustomProtectedRoute requiredRoles={['USER', 'ADMIN']}>
                                <TransferPage />
                            </CustomProtectedRoute>
                        </Layout>
                    }
                />

                <Route
                    path="/transactions"
                    element={
                        <Layout>
                            <CustomProtectedRoute requiredRoles={['USER', 'ADMIN']}>
                                <TransactionHistoryPage />
                            </CustomProtectedRoute>
                        </Layout>
                    }
                />

                <Route
                    path="/admin"
                    element={
                        <Layout>
                            <CustomProtectedRoute requiredRoles={['ADMIN']}>
                                <RoleBasedExample />
                            </CustomProtectedRoute>
                        </Layout>
                    }
                />

                <Route
                    path="/loans/apply"
                    element={
                        <Layout>
                            <CustomProtectedRoute requiredRoles={['USER', 'ADMIN']}>
                                <LoanApplicationPage />
                            </CustomProtectedRoute>
                        </Layout>
                    }
                />

                <Route
                    path="/loans/my-loans"
                    element={
                        <Layout>
                            <CustomProtectedRoute requiredRoles={['USER', 'ADMIN']}>
                                <MyLoansPage />
                            </CustomProtectedRoute>
                        </Layout>
                    }
                />

                {/* Default redirects - Prioritize Custom Login */}
                <Route
                    path="/"
                    element={
                        isAuthenticated ?
                            <Navigate to="/dashboard" replace /> :
                            <Navigate to="/custom-login" replace />
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
                                    onClick={() => window.location.href = isAuthenticated ? '/dashboard' : '/custom-login'}
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
