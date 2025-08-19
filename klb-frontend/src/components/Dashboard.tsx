import React from 'react';
import { useNavigate } from 'react-router-dom';
import useCustomAuth from '../hooks/useCustomAuth';

const Dashboard: React.FC = () => {
    const navigate = useNavigate();
    const { userInfo, hasRole, isAuthenticated, loading, logout } = useCustomAuth();

    // Debug info - temporarily show auth status
    console.log('Dashboard auth status:', {
        isAuthenticated,
        loading,
        userInfo,
        roles: userInfo?.roles,
        hasUserRole: hasRole('USER'),
        hasAdminRole: hasRole('ADMIN')
    });

    // Quick action buttons for users
    const quickActions = [
        {
            title: '👤 Thông tin cá nhân',
            description: 'Xem và cập nhật thông tin cá nhân',
            path: '/customer-info',
            roles: ['USER', 'ADMIN'],
            color: '#607d8b'
        },
        {
            title: '🏦 Tạo tài khoản',
            description: 'Tạo tài khoản thanh toán, tiết kiệm mới',
            path: '/create-account',
            roles: ['USER', 'ADMIN'],
            color: '#28a745'
        },
        {
            title: '💰 Đăng ký vay',
            description: 'Nộp đơn xin vay tiền với lãi suất ưu đãi',
            path: '/loans/apply',
            roles: ['USER', 'ADMIN'],
            color: '#4caf50'
        },
        {
            title: '� Các khoản vay của tôi',
            description: 'Xem danh sách và trạng thái các khoản vay',
            path: '/loans/my-loans',
            roles: ['USER', 'ADMIN'],
            color: '#9c27b0'
        },
        {
            title: '�💸 Chuyển tiền',
            description: 'Chuyển tiền đến tài khoản khác',
            path: '/transfer',
            roles: ['USER', 'ADMIN'],
            color: '#2196f3'
        },
        {
            title: '📊 Lịch sử giao dịch',
            description: 'Xem các giao dịch đã thực hiện',
            path: '/transactions',
            roles: ['USER', 'ADMIN'],
            color: '#ff9800'
        },
        {
            title: '👥 Quản lý khách hàng',
            description: 'Quản lý thông tin khách hàng (Admin)',
            path: '/customers',
            roles: ['ADMIN'],
            color: '#e91e63'
        }
    ];

    // Filter actions based on user roles
    const availableActions = (() => {
        if (!isAuthenticated) {
            // Khi chưa đăng nhập, hiển thị tất cả để demo
            return quickActions;
        }

        // Khi đã đăng nhập, lọc theo role
        const filteredActions = quickActions.filter(action =>
            action.roles.some(role => hasRole(role))
        );

        // Nếu không có action nào (do role không khớp), hiển thị default actions
        if (filteredActions.length === 0) {
            console.warn('No actions available for current roles:', userInfo?.roles);
            console.log('Showing default actions for authenticated user');

            // Hiển thị actions cơ bản cho user đã đăng nhập
            return [
                {
                    title: '🏦 Tạo tài khoản',
                    description: 'Tạo tài khoản thanh toán, tiết kiệm mới',
                    path: '/create-account',
                    roles: ['USER', 'ADMIN'],
                    color: '#28a745'
                },
                {
                    title: '💸 Chuyển tiền',
                    description: 'Chuyển tiền đến tài khoản khác',
                    path: '/transfer',
                    roles: ['USER', 'ADMIN'],
                    color: '#2196f3'
                },
                {
                    title: '📊 Lịch sử giao dịch',
                    description: 'Xem các giao dịch đã thực hiện',
                    path: '/transactions',
                    roles: ['USER', 'ADMIN'],
                    color: '#ff9800'
                }
            ];
        }

        return filteredActions;
    })();

    return (
        <div style={{ padding: '20px', maxWidth: '1200px', margin: '0 auto' }}>
            {/* Debug Section - Temporarily show auth status */}
            <div style={{
                backgroundColor: '#fff3cd',
                padding: '15px',
                borderRadius: '8px',
                marginBottom: '20px',
                border: '1px solid #ffeaa7',
                fontSize: '14px'
            }}>
                <h4 style={{ margin: '0 0 10px 0', color: '#856404' }}>🔍 Debug Info:</h4>
                <p><strong>Authenticated:</strong> {isAuthenticated ? '✅ Yes' : '❌ No'}</p>
                <p><strong>Loading:</strong> {loading ? '⏳ Yes' : '✅ No'}</p>
                <p><strong>Username:</strong> {userInfo?.username || 'N/A'}</p>
                <p><strong>Roles:</strong> {userInfo?.roles?.join(', ') || 'None'}</p>
                <p><strong>Has USER role:</strong> {hasRole('USER') ? '✅ Yes' : '❌ No'}</p>
                <p><strong>Has ADMIN role:</strong> {hasRole('ADMIN') ? '✅ Yes' : '❌ No'}</p>
                <p><strong>Available Actions:</strong> {availableActions.length}</p>

                {/* Debug buttons */}
                <div style={{ marginTop: '15px', display: 'flex', gap: '10px', flexWrap: 'wrap' }}>
                    <button
                        onClick={() => window.location.reload()}
                        style={{
                            padding: '8px 12px',
                            backgroundColor: '#28a745',
                            color: 'white',
                            border: 'none',
                            borderRadius: '4px',
                            cursor: 'pointer',
                            fontSize: '12px'
                        }}
                    >
                        🔄 Refresh Page
                    </button>
                    <button
                        onClick={() => {
                            console.log('Current token:', userInfo);
                            alert('Check console for token info');
                        }}
                        style={{
                            padding: '8px 12px',
                            backgroundColor: '#17a2b8',
                            color: 'white',
                            border: 'none',
                            borderRadius: '4px',
                            cursor: 'pointer',
                            fontSize: '12px'
                        }}
                    >
                        🔍 Check Token
                    </button>
                    <button
                        onClick={logout}
                        style={{
                            padding: '8px 12px',
                            backgroundColor: '#dc3545',
                            color: 'white',
                            border: 'none',
                            borderRadius: '4px',
                            cursor: 'pointer',
                            fontSize: '12px'
                        }}
                    >
                        🚪 Logout & Re-login
                    </button>
                </div>
            </div>

            {/* Welcome Section */}
            <div style={{
                backgroundColor: '#f8f9fa',
                padding: '30px',
                borderRadius: '12px',
                marginBottom: '30px',
                textAlign: 'center',
                border: '1px solid #e9ecef'
            }}>
                <h1 style={{
                    margin: '0 0 10px 0',
                    color: '#1976d2',
                    fontSize: '28px'
                }}>
                    🏦 Chào mừng đến với Kien Long Bank
                </h1>
                <p style={{
                    margin: '0 0 20px 0',
                    color: '#666',
                    fontSize: '16px'
                }}>
                    Xin chào <strong>{userInfo?.username}</strong>! Bạn có thể thực hiện các dịch vụ ngân hàng dưới đây.
                </p>
                <div style={{
                    display: 'inline-block',
                    backgroundColor: '#e3f2fd',
                    padding: '8px 16px',
                    borderRadius: '20px',
                    fontSize: '14px',
                    color: '#1976d2'
                }}>
                    Quyền: {userInfo?.roles?.join(', ') || 'User'}
                </div>
            </div>

            {/* Quick Actions */}
            <div style={{ marginBottom: '40px' }}>
                <h2 style={{
                    marginBottom: '20px',
                    color: '#333',
                    borderBottom: '2px solid #1976d2',
                    paddingBottom: '10px'
                }}>
                    ⚡ Dịch vụ nhanh
                </h2>

                <div style={{
                    display: 'grid',
                    gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))',
                    gap: '20px',
                    marginBottom: '20px'
                }}>
                    {availableActions.map((action, index) => (
                        <div
                            key={index}
                            style={{
                                backgroundColor: 'white',
                                padding: '25px',
                                borderRadius: '12px',
                                boxShadow: '0 4px 12px rgba(0,0,0,0.1)',
                                border: '1px solid #e9ecef',
                                cursor: 'pointer',
                                transition: 'all 0.3s ease',
                                transform: 'translateY(0)',
                            }}
                            onClick={() => navigate(action.path)}
                            onMouseEnter={(e) => {
                                e.currentTarget.style.transform = 'translateY(-4px)';
                                e.currentTarget.style.boxShadow = '0 8px 20px rgba(0,0,0,0.15)';
                            }}
                            onMouseLeave={(e) => {
                                e.currentTarget.style.transform = 'translateY(0)';
                                e.currentTarget.style.boxShadow = '0 4px 12px rgba(0,0,0,0.1)';
                            }}
                        >
                            <div style={{
                                display: 'flex',
                                alignItems: 'center',
                                marginBottom: '12px'
                            }}>
                                <h3 style={{
                                    margin: 0,
                                    color: action.color,
                                    fontSize: '18px',
                                    fontWeight: 'bold'
                                }}>
                                    {action.title}
                                </h3>
                            </div>
                            <p style={{
                                margin: 0,
                                color: '#666',
                                fontSize: '14px',
                                lineHeight: '1.5'
                            }}>
                                {action.description}
                            </p>
                            <div style={{
                                marginTop: '15px',
                                textAlign: 'right'
                            }}>
                                <span style={{
                                    color: action.color,
                                    fontSize: '12px',
                                    fontWeight: 'bold'
                                }}>
                                    Nhấn để tiếp tục →
                                </span>
                            </div>
                        </div>
                    ))}
                </div>
            </div>

            {/* Information Section - Dashboard chỉ hiển thị thông tin tổng quan */}
            <div style={{
                display: 'grid',
                gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))',
                gap: '20px',
                marginBottom: '30px'
            }}>
                {/* Overview Card */}
                <div style={{
                    backgroundColor: 'white',
                    padding: '25px',
                    borderRadius: '12px',
                    boxShadow: '0 2px 8px rgba(0,0,0,0.1)',
                    border: '1px solid #e9ecef',
                    textAlign: 'center'
                }}>
                    <h3 style={{
                        color: '#4caf50',
                        marginBottom: '15px',
                        fontSize: '18px'
                    }}>
                        📈 Tổng quan tài khoản
                    </h3>
                    <p style={{ color: '#666', marginBottom: '10px' }}>
                        Sử dụng menu điều hướng phía trên để truy cập các dịch vụ
                    </p>
                    <div style={{
                        backgroundColor: '#f8f9fa',
                        padding: '15px',
                        borderRadius: '8px',
                        marginTop: '15px'
                    }}>
                        <p style={{ margin: '0', fontSize: '14px', color: '#555' }}>
                            ✅ Hệ thống hoạt động bình thường<br />
                            🔐 Tài khoản đã được xác thực<br />
                            📊 Dữ liệu được cập nhật real-time
                        </p>
                    </div>
                </div>

                {/* Quick Tips */}
                <div style={{
                    backgroundColor: 'white',
                    padding: '25px',
                    borderRadius: '12px',
                    boxShadow: '0 2px 8px rgba(0,0,0,0.1)',
                    border: '1px solid #e9ecef'
                }}>
                    <h3 style={{
                        color: '#2196f3',
                        marginBottom: '15px',
                        fontSize: '18px'
                    }}>
                        💡 Hướng dẫn sử dụng
                    </h3>
                    <ul style={{
                        listStyle: 'none',
                        padding: '0',
                        margin: '0',
                        fontSize: '14px',
                        lineHeight: '1.6'
                    }}>
                        <li style={{ marginBottom: '8px' }}>• Sử dụng <strong>Dịch vụ nhanh</strong> ở trên để truy cập nhanh</li>
                        <li style={{ marginBottom: '8px' }}>• Hoặc dùng <strong>Menu điều hướng</strong> phía trên</li>
                        <li style={{ marginBottom: '8px' }}>• Kiểm tra quyền của bạn: <span style={{
                            backgroundColor: '#e3f2fd',
                            padding: '2px 8px',
                            borderRadius: '4px',
                            color: '#1976d2'
                        }}>{userInfo?.roles?.join(', ') || 'User'}</span></li>
                        <li>• Liên hệ admin nếu cần hỗ trợ thêm</li>
                    </ul>
                </div>
            </div>

            {/* Help Section */}
            <div style={{
                backgroundColor: '#fff3e0',
                padding: '20px',
                borderRadius: '12px',
                marginTop: '30px',
                border: '1px solid #ffcc02'
            }}>
                <h3 style={{
                    color: '#f57c00',
                    marginBottom: '15px',
                    display: 'flex',
                    alignItems: 'center',
                    gap: '8px'
                }}>
                    📞 Cần hỗ trợ?
                </h3>
                <div style={{
                    display: 'grid',
                    gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))',
                    gap: '15px',
                    fontSize: '14px'
                }}>
                    <div>
                        <strong>Hotline:</strong> 1900-xxxx
                    </div>
                    <div>
                        <strong>Email:</strong> support@kienlongbank.com
                    </div>
                    <div>
                        <strong>Giờ làm việc:</strong> 8:00 - 17:00 (T2-T6)
                    </div>
                </div>
            </div>
        </div>
    );
};

export { Dashboard };
export default Dashboard;
