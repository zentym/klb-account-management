import React from 'react';
import { Navigate, useLocation } from 'react-router-dom';
import useKeycloakAuth from '../hooks/useKeycloakAuth';

interface ProtectedRouteProps {
    children: React.ReactNode;
    requiredRoles?: string[];
}

export const ProtectedRoute: React.FC<ProtectedRouteProps> = ({
    children,
    requiredRoles = []
}) => {
    const { isAuthenticated, userInfo, loading, hasRole } = useKeycloakAuth();
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

    // Nếu chưa đăng nhập, chuyển hướng đến trang login
    if (!isAuthenticated) {
        // Store the intended destination
        sessionStorage.setItem('returnUrl', location.pathname);
        return <Navigate to="/login" state={{ from: location }} replace />;
    }

    // Kiểm tra quyền truy cập theo role nếu có yêu cầu
    if (requiredRoles.length > 0) {
        const hasRequiredRole = requiredRoles.some(role => hasRole(role));

        if (!hasRequiredRole) {
            return (
                <div style={{
                    textAlign: 'center',
                    padding: '40px',
                    color: '#f44336',
                    backgroundColor: '#ffebee',
                    borderRadius: '8px',
                    margin: '20px',
                    border: '1px solid #ffcdd2'
                }}>
                    <h3>🚫 Không có quyền truy cập</h3>
                    <p>Bạn không có quyền truy cập vào trang này.</p>
                    <p>Quyền yêu cầu: <strong>{requiredRoles.join(', ')}</strong></p>
                    <p>Quyền hiện tại: <strong>{userInfo?.roles?.join(', ') || 'Không xác định'}</strong></p>
                    <button
                        onClick={() => window.history.back()}
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
                        Quay lại
                    </button>
                </div>
            );
        }
    }

    // Nếu đã xác thực và có quyền, hiển thị nội dung
    return <>{children}</>;
};

export default ProtectedRoute;
