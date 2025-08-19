// User Loan List API Integration Example
// File: loan-list-service.js

/**
 * Service để quản lý API calls liên quan đến danh sách khoản vay của user
 */
export class LoanListService {
    constructor(baseUrl = '/api', authService) {
        this.baseUrl = baseUrl;
        this.authService = authService;
    }

    /**
     * Lấy danh sách khoản vay của một customer
     * @param {number} customerId - ID của customer
     * @returns {Promise<Array>} Danh sách khoản vay
     */
    async getCustomerLoans(customerId) {
        try {
            const token = await this.authService.getToken();
            const response = await fetch(`${this.baseUrl}/loans/customer/${customerId}`, {
                method: 'GET',
                headers: {
                    'Authorization': `Bearer ${token}`,
                    'Content-Type': 'application/json'
                }
            });

            if (!response.ok) {
                const error = await response.json();
                throw new Error(error.error || `HTTP ${response.status}: ${response.statusText}`);
            }

            return await response.json();
        } catch (error) {
            console.error('Error fetching customer loans:', error);
            throw error;
        }
    }

    /**
     * Lấy danh sách khoản vay của user hiện tại
     * @returns {Promise<Array>} Danh sách khoản vay
     */
    async getCurrentUserLoans() {
        try {
            const currentUser = await this.authService.getCurrentUser();
            if (!currentUser || !currentUser.customerId) {
                throw new Error('Không thể xác định customer ID của user hiện tại');
            }

            return await this.getCustomerLoans(currentUser.customerId);
        } catch (error) {
            console.error('Error fetching current user loans:', error);
            throw error;
        }
    }

    /**
     * Format trạng thái khoản vay để hiển thị
     * @param {string} status - Trạng thái khoản vay
     * @returns {object} Object chứa text và class CSS
     */
    formatLoanStatus(status) {
        const statusMap = {
            'PENDING': { text: 'Đang chờ phê duyệt', class: 'status-pending' },
            'APPROVED': { text: 'Đã phê duyệt', class: 'status-approved' },
            'REJECTED': { text: 'Đã từ chối', class: 'status-rejected' },
            'DISBURSED': { text: 'Đã giải ngân', class: 'status-disbursed' },
            'CLOSED': { text: 'Đã đóng', class: 'status-closed' }
        };

        return statusMap[status] || { text: status, class: 'status-unknown' };
    }

    /**
     * Format số tiền để hiển thị
     * @param {number} amount - Số tiền
     * @returns {string} Số tiền đã format
     */
    formatAmount(amount) {
        return new Intl.NumberFormat('vi-VN', {
            style: 'currency',
            currency: 'VND'
        }).format(amount);
    }

    /**
     * Format ngày tháng để hiển thị
     * @param {string} dateString - Chuỗi ngày tháng
     * @returns {string} Ngày tháng đã format
     */
    formatDate(dateString) {
        if (!dateString) return 'N/A';

        return new Intl.DateTimeFormat('vi-VN', {
            year: 'numeric',
            month: '2-digit',
            day: '2-digit',
            hour: '2-digit',
            minute: '2-digit'
        }).format(new Date(dateString));
    }
}

// React Hook để sử dụng với React applications
export function useLoanList(authService) {
    const [loans, setLoans] = useState([]);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState(null);

    const loanService = useMemo(() => new LoanListService('/api', authService), [authService]);

    const fetchLoans = useCallback(async (customerId = null) => {
        setLoading(true);
        setError(null);

        try {
            const loansData = customerId
                ? await loanService.getCustomerLoans(customerId)
                : await loanService.getCurrentUserLoans();

            setLoans(loansData);
        } catch (err) {
            setError(err.message);
        } finally {
            setLoading(false);
        }
    }, [loanService]);

    return {
        loans,
        loading,
        error,
        fetchLoans,
        formatStatus: loanService.formatLoanStatus,
        formatAmount: loanService.formatAmount,
        formatDate: loanService.formatDate
    };
}

// React Component Example
export function LoanListComponent({ customerId, authService }) {
    const {
        loans,
        loading,
        error,
        fetchLoans,
        formatStatus,
        formatAmount,
        formatDate
    } = useLoanList(authService);

    useEffect(() => {
        fetchLoans(customerId);
    }, [fetchLoans, customerId]);

    if (loading) {
        return (
            <div className="loan-list-loading">
                <div className="spinner"></div>
                <p>Đang tải danh sách khoản vay...</p>
            </div>
        );
    }

    if (error) {
        return (
            <div className="loan-list-error">
                <h3>Có lỗi xảy ra</h3>
                <p>{error}</p>
                <button onClick={() => fetchLoans(customerId)}>
                    Thử lại
                </button>
            </div>
        );
    }

    if (loans.length === 0) {
        return (
            <div className="loan-list-empty">
                <h3>Chưa có khoản vay nào</h3>
                <p>Bạn chưa đăng ký khoản vay nào. Hãy bắt đầu với việc đăng ký khoản vay đầu tiên!</p>
                <button onClick={() => window.location.href = '/apply-loan'}>
                    Đăng ký khoản vay
                </button>
            </div>
        );
    }

    return (
        <div className="loan-list">
            <div className="loan-list-header">
                <h2>Danh sách khoản vay</h2>
                <button
                    className="refresh-btn"
                    onClick={() => fetchLoans(customerId)}
                    title="Làm mới danh sách"
                >
                    🔄
                </button>
            </div>

            <div className="loan-list-summary">
                <p>Tổng cộng: <strong>{loans.length}</strong> khoản vay</p>
            </div>

            <div className="loan-list-items">
                {loans.map(loan => {
                    const status = formatStatus(loan.status);

                    return (
                        <div key={loan.id} className="loan-item">
                            <div className="loan-item-header">
                                <h3>Khoản vay #{loan.id}</h3>
                                <span className={`status-badge ${status.class}`}>
                                    {status.text}
                                </span>
                            </div>

                            <div className="loan-item-body">
                                <div className="loan-detail">
                                    <label>Số tiền vay:</label>
                                    <span className="amount">{formatAmount(loan.amount)}</span>
                                </div>

                                <div className="loan-detail">
                                    <label>Lãi suất:</label>
                                    <span>{loan.interestRate}% / năm</span>
                                </div>

                                <div className="loan-detail">
                                    <label>Thời hạn:</label>
                                    <span>{loan.term} tháng</span>
                                </div>

                                <div className="loan-detail">
                                    <label>Ngày đăng ký:</label>
                                    <span>{formatDate(loan.applicationDate)}</span>
                                </div>

                                {loan.approvalDate && (
                                    <div className="loan-detail">
                                        <label>Ngày phê duyệt:</label>
                                        <span>{formatDate(loan.approvalDate)}</span>
                                    </div>
                                )}

                                {loan.rejectReason && (
                                    <div className="loan-detail reject-reason">
                                        <label>Lý do từ chối:</label>
                                        <span className="reason-text">{loan.rejectReason}</span>
                                    </div>
                                )}
                            </div>

                            <div className="loan-item-actions">
                                <button
                                    className="btn-secondary"
                                    onClick={() => window.location.href = `/loans/${loan.id}`}
                                >
                                    Xem chi tiết
                                </button>

                                {loan.status === 'PENDING' && (
                                    <button
                                        className="btn-danger"
                                        onClick={() => handleCancelLoan(loan.id)}
                                    >
                                        Hủy đơn vay
                                    </button>
                                )}
                            </div>
                        </div>
                    );
                })}
            </div>
        </div>
    );
}

// CSS Styles (to be added to your stylesheet)
const loanListStyles = `
.loan-list {
    max-width: 800px;
    margin: 0 auto;
    padding: 20px;
}

.loan-list-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 20px;
}

.refresh-btn {
    background: none;
    border: 1px solid #ddd;
    border-radius: 4px;
    padding: 8px 12px;
    cursor: pointer;
    font-size: 16px;
}

.loan-list-summary {
    margin-bottom: 20px;
    padding: 10px;
    background-color: #f8f9fa;
    border-radius: 4px;
}

.loan-item {
    border: 1px solid #ddd;
    border-radius: 8px;
    margin-bottom: 16px;
    overflow: hidden;
    box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

.loan-item-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 16px 20px;
    background-color: #f8f9fa;
    border-bottom: 1px solid #ddd;
}

.status-badge {
    padding: 4px 8px;
    border-radius: 4px;
    font-size: 12px;
    font-weight: bold;
    text-transform: uppercase;
}

.status-pending { background-color: #fff3cd; color: #856404; }
.status-approved { background-color: #d4edda; color: #155724; }
.status-rejected { background-color: #f8d7da; color: #721c24; }
.status-disbursed { background-color: #d1ecf1; color: #0c5460; }
.status-closed { background-color: #e2e3e5; color: #383d41; }

.loan-item-body {
    padding: 20px;
}

.loan-detail {
    display: flex;
    justify-content: space-between;
    margin-bottom: 8px;
}

.loan-detail label {
    font-weight: 500;
    color: #666;
}

.amount {
    font-weight: bold;
    color: #007bff;
}

.reject-reason {
    flex-direction: column;
    background-color: #f8d7da;
    padding: 10px;
    border-radius: 4px;
    margin-top: 10px;
}

.reason-text {
    margin-top: 5px;
    font-style: italic;
    color: #721c24;
}

.loan-item-actions {
    padding: 16px 20px;
    background-color: #f8f9fa;
    border-top: 1px solid #ddd;
    display: flex;
    gap: 10px;
}

.btn-secondary {
    background-color: #6c757d;
    color: white;
    border: none;
    padding: 8px 16px;
    border-radius: 4px;
    cursor: pointer;
}

.btn-danger {
    background-color: #dc3545;
    color: white;
    border: none;
    padding: 8px 16px;
    border-radius: 4px;
    cursor: pointer;
}

.loan-list-loading, .loan-list-error, .loan-list-empty {
    text-align: center;
    padding: 40px 20px;
}

.spinner {
    border: 4px solid #f3f3f3;
    border-top: 4px solid #007bff;
    border-radius: 50%;
    width: 40px;
    height: 40px;
    animation: spin 1s linear infinite;
    margin: 0 auto 20px;
}

@keyframes spin {
    0% { transform: rotate(0deg); }
    100% { transform: rotate(360deg); }
}
`;

export { loanListStyles };
