import React from 'react';
import { Navigate, useLocation } from 'react-router-dom';
import useCustomAuth from '../hooks/useCustomAuth';

interface CustomProtectedRouteProps {
    children: React.ReactNode;
    requiredRoles?: string[];
}

export const CustomProtectedRoute: React.FC<CustomProtectedRouteProps> = ({
    children,
    requiredRoles = []
}) => {
    const { isAuthenticated, userInfo, loading, hasRole } = useCustomAuth();
    const location = useLocation();

    // Hiển thị loading khi đang kiểm tra xác thực
    if (loading) {
        return (
            <div style={{
                display: 'flex',
                justifyContent: 'center',
                alignItems: 'center',
                height: '50vh',
                fontSize: '18px'
            }}>
                <div>
                    <div style={{ marginBottom: '10px' }}>🔐 Đang kiểm tra quyền truy cập...</div>
                    <div style={{ textAlign: 'center' }}>
                        <div style={{
                            border: '2px solid #f3f3f3',
                            borderTop: '2px solid #3498db',
                            borderRadius: '50%',
                            width: '30px',
                            height: '30px',
                            animation: 'spin 1s linear infinite',
                            margin: '0 auto'
                        }}></div>
                    </div>
                </div>
            </div>
        );
    }

    // Nếu chưa đăng nhập, chuyển hướng đến trang custom login
    if (!isAuthenticated) {
        // Store the intended destination
        const returnUrl = location.pathname + location.search;
        return <Navigate to={`/custom-login?returnUrl=${encodeURIComponent(returnUrl)}`} replace />;
    }

    // Kiểm tra quyền truy cập nếu có yêu cầu roles
    if (requiredRoles.length > 0) {
        const userHasRequiredRole = requiredRoles.some(role => hasRole(role));

        if (!userHasRequiredRole) {
            console.log('Custom Protected Route - Access denied. Required roles:', requiredRoles, 'User roles:', userInfo?.roles);
            return (
                <div style={{
                    display: 'flex',
                    flexDirection: 'column',
                    justifyContent: 'center',
                    alignItems: 'center',
                    height: '50vh',
                    textAlign: 'center',
                    color: '#d32f2f'
                }}>
                    <div style={{ fontSize: '48px', marginBottom: '20px' }}>🚫</div>
                    <h2>Không có quyền truy cập</h2>
                    <p style={{ marginBottom: '20px', color: '#666' }}>
                        Bạn không có quyền truy cập vào trang này.
                        <br />
                        Cần quyền: {requiredRoles.join(' hoặc ')}
                        <br />
                        Quyền hiện tại: {userInfo?.roles?.join(', ') || 'Không có'}
                    </p>
                    <div style={{ display: 'flex', gap: '10px' }}>
                        <button
                            onClick={() => window.location.href = '/dashboard'}
                            style={{
                                padding: '10px 20px',
                                backgroundColor: '#1976d2',
                                color: 'white',
                                border: 'none',
                                borderRadius: '4px',
                                cursor: 'pointer'
                            }}
                        >
                            Về trang chủ
                        </button>
                        <button
                            onClick={() => window.location.href = '/custom-login'}
                            style={{
                                padding: '10px 20px',
                                backgroundColor: '#f44336',
                                color: 'white',
                                border: 'none',
                                borderRadius: '4px',
                                cursor: 'pointer'
                            }}
                        >
                            Đăng xuất
                        </button>
                    </div>
                </div>
            );
        }
    }

    console.log('Custom Protected Route - Access granted. User:', userInfo?.username, 'Roles:', userInfo?.roles);
    return <>{children}</>;
};

export default CustomProtectedRoute;
