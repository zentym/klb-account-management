import React, { useState, useEffect } from 'react';
import api from '../config/api';

// Định nghĩa kiểu dữ liệu cho Transaction
interface Transaction {
    id: number;
    fromAccountId: number;
    toAccountId: number;
    amount: number;
    description: string;
    transactionDate: string;
    status: string;
    transactionType: string;
}

// Định nghĩa kiểu dữ liệu cho Account
interface Account {
    id?: number;
    accountNumber: string;
    accountType: string;
    balance: number;
    status: string;
    openDate: string;
}

interface TransactionHistoryProps {
    account: Account;
    onClose: () => void;
}

export const TransactionHistory: React.FC<TransactionHistoryProps> = ({ account, onClose }) => {
    const [transactions, setTransactions] = useState<Transaction[]>([]);
    const [loading, setLoading] = useState<boolean>(false);
    const [error, setError] = useState<string>('');

    // Hàm gọi API để lấy lịch sử giao dịch
    const fetchTransactionHistory = async () => {
        if (!account.id) {
            setError('Account ID is missing');
            return;
        }

        try {
            setLoading(true);
            setError('');
            const response = await api.get(`/api/transactions/account/${account.id}`);

            // Kiểm tra cấu trúc response
            if (response.data && response.data.transactions) {
                setTransactions(response.data.transactions);
            } else if (Array.isArray(response.data)) {
                setTransactions(response.data);
            } else {
                setTransactions([]);
            }
        } catch (err: any) {
            setError(`Failed to fetch transaction history: ${err.response?.data?.error || err.message}`);
            console.error('Error fetching transaction history:', err);
        } finally {
            setLoading(false);
        }
    };

    // Tự động gọi hàm fetchTransactionHistory khi component được render
    useEffect(() => {
        fetchTransactionHistory();
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [account.id]);

    // Hàm để xác định loại giao dịch (Ghi Nợ/Ghi Có)
    const getTransactionType = (transaction: Transaction) => {
        if (!account.id) {
            return { type: 'UNKNOWN', label: 'Không xác định', color: '#757575', icon: '❓' };
        }

        if (transaction.fromAccountId === account.id) {
            return { type: 'DEBIT', label: 'Ghi Nợ', color: '#d32f2f', icon: '➖' };
        } else if (transaction.toAccountId === account.id) {
            return { type: 'CREDIT', label: 'Ghi Có', color: '#2e7d32', icon: '➕' };
        }
        return { type: 'UNKNOWN', label: 'Không xác định', color: '#757575', icon: '❓' };
    };

    // Hàm để tạo mô tả chi tiết giao dịch
    const getTransactionDescription = (transaction: Transaction) => {
        if (!account.id) {
            return transaction.description || 'Giao dịch không xác định';
        }

        const transactionTypeInfo = getTransactionType(transaction);

        if (transactionTypeInfo.type === 'DEBIT') {
            return `Chuyển tiền đến tài khoản #${transaction.toAccountId}`;
        } else if (transactionTypeInfo.type === 'CREDIT') {
            return `Nhận tiền từ tài khoản #${transaction.fromAccountId}`;
        }
        return transaction.description || 'Giao dịch không xác định';
    };

    return (
        <div style={{
            position: 'fixed',
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            backgroundColor: 'rgba(0, 0, 0, 0.5)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            zIndex: 1000
        }}>
            <div style={{
                backgroundColor: 'white',
                borderRadius: '12px',
                padding: '24px',
                maxWidth: '900px',
                width: '90%',
                maxHeight: '80vh',
                overflow: 'auto',
                boxShadow: '0 10px 25px rgba(0,0,0,0.15)'
            }}>
                {/* Header */}
                <div style={{
                    display: 'flex',
                    justifyContent: 'space-between',
                    alignItems: 'center',
                    marginBottom: '20px',
                    borderBottom: '2px solid #f0f0f0',
                    paddingBottom: '15px'
                }}>
                    <div>
                        <h2 style={{ margin: 0, color: '#333', fontSize: '24px' }}>
                            📊 Lịch sử Giao dịch
                        </h2>
                        <p style={{ margin: '5px 0 0 0', color: '#666', fontSize: '14px' }}>
                            Tài khoản: <strong>{account.accountNumber}</strong> |
                            Loại: <strong>{account.accountType}</strong> |
                            Số dư: <strong style={{ color: account.balance >= 0 ? '#2e7d32' : '#d32f2f' }}>
                                ${account.balance.toLocaleString('en-US', { minimumFractionDigits: 2 })}
                            </strong>
                        </p>
                    </div>
                    <button
                        onClick={onClose}
                        style={{
                            background: '#f44336',
                            color: 'white',
                            border: 'none',
                            borderRadius: '50%',
                            width: '35px',
                            height: '35px',
                            fontSize: '18px',
                            cursor: 'pointer',
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center'
                        }}
                    >
                        ✕
                    </button>
                </div>

                {/* Error Display */}
                {error && (
                    <div style={{
                        padding: '12px',
                        backgroundColor: '#ffebee',
                        color: '#c62828',
                        borderRadius: '6px',
                        marginBottom: '20px',
                        border: '1px solid #ffcdd2'
                    }}>
                        ⚠️ {error}
                    </div>
                )}

                {/* Loading */}
                {loading && (
                    <div style={{
                        textAlign: 'center',
                        padding: '40px',
                        color: '#666'
                    }}>
                        🔄 Đang tải lịch sử giao dịch...
                    </div>
                )}

                {/* Transaction List */}
                {!loading && !error && (
                    <div>
                        {transactions.length === 0 ? (
                            <div style={{
                                textAlign: 'center',
                                padding: '40px',
                                color: '#666',
                                backgroundColor: '#f9f9f9',
                                borderRadius: '8px',
                                border: '2px dashed #ddd'
                            }}>
                                📭 Không có giao dịch nào được tìm thấy
                            </div>
                        ) : (
                            <div style={{ overflowX: 'auto' }}>
                                <table style={{
                                    width: '100%',
                                    borderCollapse: 'collapse',
                                    backgroundColor: 'white',
                                    boxShadow: '0 2px 4px rgba(0,0,0,0.1)',
                                    borderRadius: '8px',
                                    overflow: 'hidden'
                                }}>
                                    <thead>
                                        <tr style={{ backgroundColor: '#f8f9fa' }}>
                                            <th style={{ padding: '12px', border: '1px solid #dee2e6', textAlign: 'left', fontWeight: '600', color: '#495057' }}>ID</th>
                                            <th style={{ padding: '12px', border: '1px solid #dee2e6', textAlign: 'left', fontWeight: '600', color: '#495057' }}>Ngày Giao dịch</th>
                                            <th style={{ padding: '12px', border: '1px solid #dee2e6', textAlign: 'left', fontWeight: '600', color: '#495057' }}>Mô tả</th>
                                            <th style={{ padding: '12px', border: '1px solid #dee2e6', textAlign: 'right', fontWeight: '600', color: '#495057' }}>Số tiền</th>
                                            <th style={{ padding: '12px', border: '1px solid #dee2e6', textAlign: 'center', fontWeight: '600', color: '#495057' }}>Loại</th>
                                            <th style={{ padding: '12px', border: '1px solid #dee2e6', textAlign: 'center', fontWeight: '600', color: '#495057' }}>Trạng thái</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        {transactions.map((transaction, index) => {
                                            const transactionTypeInfo = getTransactionType(transaction);
                                            return (
                                                <tr key={transaction.id} style={{
                                                    backgroundColor: index % 2 === 0 ? 'white' : '#fafbfc'
                                                }}>
                                                    <td style={{ padding: '12px', border: '1px solid #dee2e6', fontSize: '14px' }}>
                                                        #{transaction.id}
                                                    </td>
                                                    <td style={{ padding: '12px', border: '1px solid #dee2e6', fontSize: '14px' }}>
                                                        📅 {new Date(transaction.transactionDate).toLocaleString('vi-VN')}
                                                    </td>
                                                    <td style={{ padding: '12px', border: '1px solid #dee2e6', fontSize: '14px' }}>
                                                        {getTransactionDescription(transaction)}
                                                        {transaction.description && transaction.description !== getTransactionDescription(transaction) && (
                                                            <div style={{ fontSize: '12px', color: '#666', marginTop: '2px' }}>
                                                                💬 {transaction.description}
                                                            </div>
                                                        )}
                                                    </td>
                                                    <td style={{
                                                        padding: '12px',
                                                        border: '1px solid #dee2e6',
                                                        textAlign: 'right',
                                                        fontWeight: 'bold',
                                                        fontSize: '15px',
                                                        color: transactionTypeInfo.color
                                                    }}>
                                                        {transactionTypeInfo.icon} ${transaction.amount.toLocaleString('en-US', { minimumFractionDigits: 2 })}
                                                    </td>
                                                    <td style={{ padding: '12px', border: '1px solid #dee2e6', textAlign: 'center' }}>
                                                        <span style={{
                                                            padding: '4px 8px',
                                                            borderRadius: '12px',
                                                            fontSize: '12px',
                                                            fontWeight: '600',
                                                            backgroundColor: transactionTypeInfo.type === 'CREDIT' ? '#e8f5e8' : '#fff3cd',
                                                            color: transactionTypeInfo.color
                                                        }}>
                                                            {transactionTypeInfo.icon} {transactionTypeInfo.label}
                                                        </span>
                                                    </td>
                                                    <td style={{ padding: '12px', border: '1px solid #dee2e6', textAlign: 'center' }}>
                                                        <span style={{
                                                            padding: '4px 8px',
                                                            borderRadius: '12px',
                                                            fontSize: '12px',
                                                            fontWeight: '600',
                                                            backgroundColor: transaction.status === 'COMPLETED' ? '#e8f5e8' : '#fff3cd',
                                                            color: transaction.status === 'COMPLETED' ? '#2e7d32' : '#856404'
                                                        }}>
                                                            {transaction.status === 'COMPLETED' ? '✅ Hoàn thành' : '⏳ ' + transaction.status}
                                                        </span>
                                                    </td>
                                                </tr>
                                            );
                                        })}
                                    </tbody>
                                </table>

                                {/* Summary */}
                                <div style={{
                                    marginTop: '20px',
                                    padding: '15px',
                                    backgroundColor: '#f8f9fa',
                                    borderRadius: '8px',
                                    border: '1px solid #dee2e6'
                                }}>
                                    <h4 style={{ margin: '0 0 10px 0', color: '#495057' }}>📈 Tóm tắt</h4>
                                    <div style={{ display: 'flex', gap: '20px', flexWrap: 'wrap' }}>
                                        <span>
                                            <strong>Tổng giao dịch:</strong> {transactions.length}
                                        </span>
                                        <span>
                                            <strong style={{ color: '#2e7d32' }}>Ghi Có:</strong> {transactions.filter(t => getTransactionType(t).type === 'CREDIT').length}
                                        </span>
                                        <span>
                                            <strong style={{ color: '#d32f2f' }}>Ghi Nợ:</strong> {transactions.filter(t => getTransactionType(t).type === 'DEBIT').length}
                                        </span>
                                    </div>
                                </div>
                            </div>
                        )}
                    </div>
                )}
            </div>
        </div>
    );
};
