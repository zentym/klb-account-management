import React, { useState } from 'react';
import api from '../config/api';
import useCustomAuth from '../hooks/useCustomAuth';

interface TransferRequest {
    fromAccountId: number;
    toAccountId: number;
    amount: number;
}

interface TransferResponse {
    message?: string;
    error?: string;
    transaction?: any;
}

const TransferPage: React.FC = () => {
    const { isAuthenticated, userInfo, hasRole } = useCustomAuth();
    const isAdmin = () => hasRole('ADMIN');
    const [fromAccountId, setFromAccountId] = useState<string>('');
    const [toAccountId, setToAccountId] = useState<string>('');
    const [amount, setAmount] = useState<string>('');
    const [loading, setLoading] = useState<boolean>(false);
    const [message, setMessage] = useState<string>('');
    const [error, setError] = useState<string>('');

    // Kiểm tra authentication
    if (!isAuthenticated) {
        return (
            <div style={{
                padding: '20px',
                textAlign: 'center',
                backgroundColor: '#f5f5f5',
                border: '1px solid #ddd',
                borderRadius: '8px',
                margin: '20px'
            }}>
                <h3>🔒 Yêu cầu đăng nhập</h3>
                <p>Vui lòng đăng nhập để thực hiện chuyển tiền.</p>
            </div>
        );
    }

    // Kiểm tra quyền hạn - USER và Admin đều có thể chuyển tiền
    const canTransfer = hasRole('USER') || hasRole('ADMIN');
    if (!canTransfer) {
        return (
            <div style={{
                padding: '20px',
                textAlign: 'center',
                backgroundColor: '#fff3cd',
                border: '1px solid #ffeaa7',
                borderRadius: '8px',
                margin: '20px'
            }}>
                <h3>⚠️ Không có quyền truy cập</h3>
                <p>Bạn cần có quyền USER hoặc ADMIN để thực hiện chuyển tiền.</p>
                <p>Quyền hiện tại: <strong>{userInfo?.roles?.join(', ') || 'N/A'}</strong></p>
            </div>
        );
    }

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();

        // Reset messages
        setMessage('');
        setError('');

        // Validate input
        if (!fromAccountId || !toAccountId || !amount) {
            setError('Vui lòng điền đầy đủ thông tin');
            return;
        }

        if (parseFloat(amount) <= 0) {
            setError('Số tiền phải lớn hơn 0');
            return;
        }

        if (fromAccountId === toAccountId) {
            setError('Không thể chuyển tiền cho chính tài khoản của mình');
            return;
        }

        setLoading(true);

        try {
            const transferData: TransferRequest = {
                fromAccountId: parseInt(fromAccountId),
                toAccountId: parseInt(toAccountId),
                amount: parseFloat(amount)
            };

            const response = await api.post<TransferResponse>(
                '/api/transactions/transfer',
                transferData
            );

            if (response.data.message) {
                setMessage(response.data.message);
                // Reset form after successful transfer
                setFromAccountId('');
                setToAccountId('');
                setAmount('');
            }
        } catch (err: any) {
            console.error('Transfer error details:', err);

            if (err.response?.data?.error) {
                setError(err.response.data.error);
            } else if (err.response?.status) {
                // Xử lý các mã lỗi HTTP cụ thể
                switch (err.response.status) {
                    case 400:
                        setError(`Lỗi 400 - Dữ liệu không hợp lệ: ${err.response.data?.message || 'Kiểm tra lại thông tin đầu vào'}`);
                        break;
                    case 404:
                        setError('Lỗi 404 - Không tìm thấy API endpoint hoặc tài khoản');
                        break;
                    case 500:
                        setError('Lỗi 500 - Lỗi server nội bộ: Có thể do table transactions chưa được tạo hoặc database connection');
                        break;
                    default:
                        setError(`Lỗi HTTP ${err.response.status}: ${err.response.statusText || 'Không xác định'}`);
                }
            } else if (err.code === 'ECONNREFUSED') {
                setError('Lỗi kết nối: Không thể kết nối đến server backend (http://localhost:8080)');
            } else if (err.code === 'NETWORK_ERROR') {
                setError('Lỗi mạng: Kiểm tra kết nối internet hoặc CORS settings');
            } else if (err.message) {
                setError(`Lỗi: ${err.message}`);
            } else {
                setError('Có lỗi không xác định xảy ra trong quá trình chuyển khoản');
            }
        } finally {
            setLoading(false);
        }
    };

    const resetForm = () => {
        setFromAccountId('');
        setToAccountId('');
        setAmount('');
        setMessage('');
        setError('');
    };

    return (
        <div style={{
            maxWidth: '600px',
            margin: '20px auto',
            padding: '20px',
            border: '1px solid #ddd',
            borderRadius: '8px',
            backgroundColor: '#f9f9f9'
        }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
                <h2 style={{
                    color: '#333',
                    margin: '0'
                }}>
                    Chuyển Khoản
                </h2>
                <div style={{ fontSize: '14px', color: '#666' }}>
                    Đăng nhập: <strong>{userInfo?.username || 'N/A'}</strong> |
                    Quyền: <strong>{userInfo?.roles?.join(', ') || 'N/A'}</strong>
                    {isAdmin() && <span style={{ color: '#4caf50' }}> (Admin)</span>}
                </div>
            </div>

            <form onSubmit={handleSubmit}>
                <div style={{ marginBottom: '15px' }}>
                    <label style={{
                        display: 'block',
                        marginBottom: '5px',
                        fontWeight: 'bold',
                        color: '#555'
                    }}>
                        Từ Tài Khoản (ID):
                    </label>
                    <input
                        type="number"
                        value={fromAccountId}
                        onChange={(e) => setFromAccountId(e.target.value)}
                        placeholder="Nhập ID tài khoản gửi"
                        style={{
                            width: '100%',
                            padding: '10px',
                            border: '1px solid #ccc',
                            borderRadius: '4px',
                            fontSize: '16px'
                        }}
                        disabled={loading}
                    />
                </div>

                <div style={{ marginBottom: '15px' }}>
                    <label style={{
                        display: 'block',
                        marginBottom: '5px',
                        fontWeight: 'bold',
                        color: '#555'
                    }}>
                        Đến Tài Khoản (ID):
                    </label>
                    <input
                        type="number"
                        value={toAccountId}
                        onChange={(e) => setToAccountId(e.target.value)}
                        placeholder="Nhập ID tài khoản nhận"
                        style={{
                            width: '100%',
                            padding: '10px',
                            border: '1px solid #ccc',
                            borderRadius: '4px',
                            fontSize: '16px'
                        }}
                        disabled={loading}
                    />
                </div>

                <div style={{ marginBottom: '20px' }}>
                    <label style={{
                        display: 'block',
                        marginBottom: '5px',
                        fontWeight: 'bold',
                        color: '#555'
                    }}>
                        Số Tiền:
                    </label>
                    <input
                        type="number"
                        step="0.01"
                        min="0"
                        value={amount}
                        onChange={(e) => setAmount(e.target.value)}
                        placeholder="Nhập số tiền cần chuyển"
                        style={{
                            width: '100%',
                            padding: '10px',
                            border: '1px solid #ccc',
                            borderRadius: '4px',
                            fontSize: '16px'
                        }}
                        disabled={loading}
                    />
                </div>

                <div style={{
                    display: 'flex',
                    gap: '10px',
                    justifyContent: 'center'
                }}>
                    <button
                        type="submit"
                        disabled={loading}
                        style={{
                            padding: '12px 24px',
                            backgroundColor: loading ? '#ccc' : '#007bff',
                            color: 'white',
                            border: 'none',
                            borderRadius: '4px',
                            fontSize: '16px',
                            cursor: loading ? 'not-allowed' : 'pointer',
                            fontWeight: 'bold'
                        }}
                    >
                        {loading ? 'Đang xử lý...' : 'Chuyển Khoản'}
                    </button>

                    <button
                        type="button"
                        onClick={resetForm}
                        disabled={loading}
                        style={{
                            padding: '12px 24px',
                            backgroundColor: '#6c757d',
                            color: 'white',
                            border: 'none',
                            borderRadius: '4px',
                            fontSize: '16px',
                            cursor: loading ? 'not-allowed' : 'pointer'
                        }}
                    >
                        Làm Mới
                    </button>
                </div>
            </form>

            {/* Success Message */}
            {message && (
                <div style={{
                    marginTop: '20px',
                    padding: '10px',
                    backgroundColor: '#d4edda',
                    color: '#155724',
                    border: '1px solid #c3e6cb',
                    borderRadius: '4px',
                    textAlign: 'center'
                }}>
                    ✅ {message}
                </div>
            )}

            {/* Error Message */}
            {error && (
                <div style={{
                    marginTop: '20px',
                    padding: '10px',
                    backgroundColor: '#f8d7da',
                    color: '#721c24',
                    border: '1px solid #f5c6cb',
                    borderRadius: '4px',
                    textAlign: 'center'
                }}>
                    ❌ {error}
                </div>
            )}
        </div>
    );
};

export default TransferPage;
