import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import useKeycloakAuth from '../hooks/useKeycloakAuth';
import api from '../config/api';

// Định nghĩa interface cho Loan
interface Loan {
    id: number;
    customerId: number;
    loanType: string;
    amount: number;
    interestRate: number;
    termMonths: number;
    monthlyPayment: number;
    status: 'PENDING' | 'APPROVED' | 'REJECTED' | 'ACTIVE' | 'CLOSED';
    applicationDate: string;
    approvalDate?: string;
    rejectionReason?: string;
    collateral?: string;
    purpose: string;
}

// Interface cho API response
interface LoansResponse {
    data?: Loan[];
    error?: string;
}

const MyLoansPage: React.FC = () => {
    const navigate = useNavigate();
    const { userInfo, token, isAuthenticated } = useKeycloakAuth();
    const [loans, setLoans] = useState<Loan[]>([]);
    const [loading, setLoading] = useState<boolean>(true);
    const [error, setError] = useState<string | null>(null);

    // Giả định customerId = 1 cho demo, trong thực tế sẽ lấy từ token hoặc API
    // TODO: Implement proper customer ID extraction from JWT token
    const customerId = 1;

    // Fetch loans data
    useEffect(() => {
        if (!isAuthenticated || !token) {
            setLoading(false);
            return;
        }

        const fetchLoans = async () => {
            try {
                setLoading(true);
                setError(null);

                console.log('📋 Fetching loans for customer:', customerId);
                const response = await api.get(`/api/loans/customer/${customerId}`);

                console.log('✅ Loans fetched successfully:', response.data);

                // Xử lý response data
                if (Array.isArray(response.data)) {
                    setLoans(response.data);
                } else if (response.data && Array.isArray(response.data.data)) {
                    setLoans(response.data.data);
                } else {
                    setLoans([]);
                }
            } catch (err: any) {
                console.error('❌ Error fetching loans:', err);

                if (err.response?.status === 403) {
                    setError('Bạn không có quyền xem thông tin khoản vay này.');
                } else if (err.response?.status === 404) {
                    setError('Không tìm thấy thông tin khoản vay.');
                } else if (err.response?.data?.error) {
                    setError(err.response.data.error);
                } else {
                    setError('Có lỗi xảy ra khi tải danh sách khoản vay. Vui lòng thử lại sau.');
                }
            } finally {
                setLoading(false);
            }
        };

        fetchLoans();
    }, [isAuthenticated, token, customerId]);

    // Format currency
    const formatCurrency = (amount: number): string => {
        return new Intl.NumberFormat('vi-VN', {
            style: 'currency',
            currency: 'VND'
        }).format(amount);
    };

    // Format date
    const formatDate = (dateString: string): string => {
        return new Date(dateString).toLocaleDateString('vi-VN', {
            year: 'numeric',
            month: '2-digit',
            day: '2-digit'
        });
    };

    // Get status badge
    const getStatusBadge = (status: string) => {
        const statusConfig = {
            PENDING: { color: '#ff9800', bg: '#fff3e0', text: 'Đang chờ duyệt' },
            APPROVED: { color: '#4caf50', bg: '#e8f5e8', text: 'Đã duyệt' },
            REJECTED: { color: '#f44336', bg: '#ffebee', text: 'Từ chối' },
            ACTIVE: { color: '#2196f3', bg: '#e3f2fd', text: 'Đang hoạt động' },
            CLOSED: { color: '#757575', bg: '#f5f5f5', text: 'Đã đóng' }
        };

        const config = statusConfig[status as keyof typeof statusConfig] ||
            { color: '#757575', bg: '#f5f5f5', text: status };

        return (
            <span style={{
                padding: '4px 12px',
                borderRadius: '12px',
                fontSize: '12px',
                fontWeight: 'bold',
                color: config.color,
                backgroundColor: config.bg,
                border: `1px solid ${config.color}20`
            }}>
                {config.text}
            </span>
        );
    };

    // Loading state
    if (loading) {
        return (
            <div style={{
                padding: '20px',
                textAlign: 'center',
                minHeight: '400px',
                display: 'flex',
                flexDirection: 'column',
                justifyContent: 'center',
                alignItems: 'center'
            }}>
                <div style={{
                    border: '3px solid #f3f3f3',
                    borderTop: '3px solid #1976d2',
                    borderRadius: '50%',
                    width: '40px',
                    height: '40px',
                    animation: 'spin 1s linear infinite',
                    marginBottom: '20px'
                }}></div>
                <p>Đang tải danh sách khoản vay...</p>
                <style>{`
                    @keyframes spin {
                        0% { transform: rotate(0deg); }
                        100% { transform: rotate(360deg); }
                    }
                `}</style>
            </div>
        );
    }

    return (
        <div style={{ padding: '20px', maxWidth: '1200px', margin: '0 auto' }}>
            {/* Header */}
            <div style={{
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'center',
                marginBottom: '30px',
                paddingBottom: '15px',
                borderBottom: '2px solid #1976d2'
            }}>
                <h1 style={{
                    margin: 0,
                    color: '#1976d2',
                    fontSize: '28px',
                    display: 'flex',
                    alignItems: 'center'
                }}>
                    💰 Các khoản vay của tôi
                </h1>
                <div style={{ display: 'flex', gap: '10px' }}>
                    <button
                        onClick={() => navigate('/loans/apply')}
                        style={{
                            padding: '10px 20px',
                            backgroundColor: '#4caf50',
                            color: 'white',
                            border: 'none',
                            borderRadius: '6px',
                            cursor: 'pointer',
                            fontSize: '14px',
                            fontWeight: 'bold'
                        }}
                    >
                        ➕ Đăng ký vay mới
                    </button>
                    <button
                        onClick={() => navigate('/dashboard')}
                        style={{
                            padding: '10px 20px',
                            backgroundColor: '#757575',
                            color: 'white',
                            border: 'none',
                            borderRadius: '6px',
                            cursor: 'pointer',
                            fontSize: '14px'
                        }}
                    >
                        ← Về trang chủ
                    </button>
                </div>
            </div>

            {/* Error state */}
            {error && (
                <div style={{
                    backgroundColor: '#ffebee',
                    border: '1px solid #f44336',
                    borderRadius: '8px',
                    padding: '15px',
                    marginBottom: '20px',
                    color: '#d32f2f'
                }}>
                    <strong>⚠️ Lỗi:</strong> {error}
                    <button
                        onClick={() => window.location.reload()}
                        style={{
                            marginLeft: '15px',
                            padding: '5px 10px',
                            backgroundColor: '#f44336',
                            color: 'white',
                            border: 'none',
                            borderRadius: '4px',
                            cursor: 'pointer',
                            fontSize: '12px'
                        }}
                    >
                        Thử lại
                    </button>
                </div>
            )}

            {/* Loans table */}
            {!error && (
                <div style={{
                    backgroundColor: 'white',
                    borderRadius: '8px',
                    boxShadow: '0 2px 8px rgba(0,0,0,0.1)',
                    overflow: 'hidden'
                }}>
                    {loans.length === 0 ? (
                        <div style={{
                            padding: '40px',
                            textAlign: 'center',
                            color: '#666'
                        }}>
                            <h3 style={{ color: '#999', marginBottom: '15px' }}>
                                📋 Chưa có khoản vay nào
                            </h3>
                            <p style={{ marginBottom: '20px' }}>
                                Bạn chưa có khoản vay nào trong hệ thống. Hãy đăng ký một khoản vay mới để bắt đầu!
                            </p>
                            <button
                                onClick={() => navigate('/loans/apply')}
                                style={{
                                    padding: '12px 24px',
                                    backgroundColor: '#4caf50',
                                    color: 'white',
                                    border: 'none',
                                    borderRadius: '6px',
                                    cursor: 'pointer',
                                    fontSize: '16px',
                                    fontWeight: 'bold'
                                }}
                            >
                                ➕ Đăng ký vay ngay
                            </button>
                        </div>
                    ) : (
                        <>
                            {/* Table Header */}
                            <div style={{
                                display: 'grid',
                                gridTemplateColumns: '100px 120px 150px 100px 80px 120px 120px 150px',
                                gap: '10px',
                                padding: '15px',
                                backgroundColor: '#f5f5f5',
                                fontWeight: 'bold',
                                fontSize: '14px',
                                color: '#555',
                                borderBottom: '1px solid #ddd'
                            }}>
                                <div>Mã vay</div>
                                <div>Ngày đăng ký</div>
                                <div>Số tiền</div>
                                <div>Kỳ hạn</div>
                                <div>Lãi suất</div>
                                <div>Trả hàng tháng</div>
                                <div>Trạng thái</div>
                                <div>Mục đích</div>
                            </div>

                            {/* Table Body */}
                            {loans.map((loan) => (
                                <div
                                    key={loan.id}
                                    style={{
                                        display: 'grid',
                                        gridTemplateColumns: '100px 120px 150px 100px 80px 120px 120px 150px',
                                        gap: '10px',
                                        padding: '15px',
                                        borderBottom: '1px solid #eee',
                                        fontSize: '13px',
                                        alignItems: 'center',
                                        transition: 'background-color 0.2s',
                                        cursor: 'pointer'
                                    }}
                                    onMouseEnter={(e) => {
                                        e.currentTarget.style.backgroundColor = '#f9f9f9';
                                    }}
                                    onMouseLeave={(e) => {
                                        e.currentTarget.style.backgroundColor = 'transparent';
                                    }}
                                >
                                    <div style={{ fontWeight: 'bold', color: '#1976d2' }}>
                                        #{loan.id}
                                    </div>
                                    <div>{formatDate(loan.applicationDate)}</div>
                                    <div style={{ fontWeight: 'bold', color: '#2e7d32' }}>
                                        {formatCurrency(loan.amount)}
                                    </div>
                                    <div>{loan.termMonths} tháng</div>
                                    <div>{loan.interestRate}%</div>
                                    <div style={{ color: '#ff6f00' }}>
                                        {formatCurrency(loan.monthlyPayment)}
                                    </div>
                                    <div>{getStatusBadge(loan.status)}</div>
                                    <div style={{
                                        whiteSpace: 'nowrap',
                                        overflow: 'hidden',
                                        textOverflow: 'ellipsis',
                                        maxWidth: '140px'
                                    }} title={loan.purpose}>
                                        {loan.purpose}
                                    </div>
                                </div>
                            ))}
                        </>
                    )}
                </div>
            )}

            {/* Summary section for approved loans */}
            {!error && loans.length > 0 && (
                <div style={{
                    marginTop: '30px',
                    padding: '20px',
                    backgroundColor: '#e3f2fd',
                    borderRadius: '8px',
                    border: '1px solid #2196f3'
                }}>
                    <h3 style={{ margin: '0 0 15px 0', color: '#1976d2' }}>
                        📊 Tổng quan khoản vay
                    </h3>
                    <div style={{
                        display: 'grid',
                        gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))',
                        gap: '15px'
                    }}>
                        <div>
                            <strong>Tổng số khoản vay:</strong> {loans.length}
                        </div>
                        <div>
                            <strong>Đang chờ duyệt:</strong> {loans.filter(l => l.status === 'PENDING').length}
                        </div>
                        <div>
                            <strong>Đã duyệt:</strong> {loans.filter(l => l.status === 'APPROVED' || l.status === 'ACTIVE').length}
                        </div>
                        <div>
                            <strong>Tổng dư nợ:</strong> {formatCurrency(
                                loans
                                    .filter(l => l.status === 'APPROVED' || l.status === 'ACTIVE')
                                    .reduce((sum, l) => sum + l.amount, 0)
                            )}
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
};

export default MyLoansPage;
