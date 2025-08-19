import React from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import useCustomAuth from '../hooks/useCustomAuth';

export const Navigation: React.FC = () => {
    const navigate = useNavigate();
    const location = useLocation();
    const { userInfo, hasRole } = useCustomAuth();

    const navItems = [
        { path: '/dashboard', label: '🏠 Trang chủ', roles: ['USER', 'ADMIN'] },
        { path: '/customer-info', label: '👤 Thông tin cá nhân', roles: ['USER', 'ADMIN'] },
        { path: '/customers', label: '👥 Quản lý khách hàng', roles: ['ADMIN'] },
        { path: '/transfer', label: '💸 Chuyển tiền', roles: ['USER', 'ADMIN'] },
        { path: '/loans/apply', label: '💰 Đăng ký vay', roles: ['USER', 'ADMIN'] },
        { path: '/loans/my-loans', label: '📋 Khoản vay của tôi', roles: ['USER', 'ADMIN'] },
        { path: '/transactions', label: '📊 Lịch sử giao dịch', roles: ['USER', 'ADMIN'] },
        { path: '/admin', label: '⚙️ Quản trị', roles: ['ADMIN'] }
    ];

    // Lọc menu items dựa trên role của user
    const availableItems = navItems.filter(item =>
        item.roles.some(role => hasRole(role))
    );

    const isActive = (path: string) => location.pathname === path;

    return (
        <nav style={{
            backgroundColor: '#f5f5f5',
            padding: '10px 20px',
            borderBottom: '1px solid #ddd',
            marginBottom: '20px'
        }}>
            <div style={{
                display: 'flex',
                gap: '15px',
                flexWrap: 'wrap'
            }}>
                {availableItems.map((item) => (
                    <button
                        key={item.path}
                        onClick={() => navigate(item.path)}
                        style={{
                            padding: '8px 16px',
                            backgroundColor: isActive(item.path) ? '#1976d2' : 'transparent',
                            color: isActive(item.path) ? 'white' : '#1976d2',
                            border: '1px solid #1976d2',
                            borderRadius: '4px',
                            cursor: 'pointer',
                            fontSize: '14px',
                            fontWeight: isActive(item.path) ? 'bold' : 'normal',
                            transition: 'all 0.3s ease'
                        }}
                    >
                        {item.label}
                    </button>
                ))}
            </div>
        </nav>
    );
};

export default Navigation;
