import React, { useState, useEffect } from 'react';
import api from '../config/api';
import { TransactionHistory } from './TransactionHistory';
import useKeycloakAuth from '../hooks/useKeycloakAuth';
import { authService } from '../services/authService';
import TokenDebugComponent from './TokenDebugComponent';

// Định nghĩa kiểu dữ liệu cho Customer
interface Customer {
    id?: number;
    fullName: string;
    email: string;
    phone: string;
    address: string;
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

export const CustomerPage = () => {
    const { isAuthenticated, userInfo, hasRole, isAdmin, loading: authLoading } = useKeycloakAuth();
    const [customers, setCustomers] = useState<Customer[]>([]);
    const [newCustomer, setNewCustomer] = useState<Customer>({
        fullName: '', email: '', phone: '', address: ''
    });
    const [loading, setLoading] = useState<boolean>(false);
    const [error, setError] = useState<string>('');
    const [editingCustomer, setEditingCustomer] = useState<Customer | null>(null);

    // State cho quản lý tài khoản
    const [selectedCustomerId, setSelectedCustomerId] = useState<number | null>(null);
    const [accounts, setAccounts] = useState<Account[]>([]);
    const [newAccount, setNewAccount] = useState<{ accountType: string, balance: number }>({
        accountType: '', balance: 0
    });

    // State cho xem lịch sử giao dịch
    const [viewingHistoryFor, setViewingHistoryFor] = useState<Account | null>(null);

    // Hàm gọi API để lấy danh sách khách hàng
    const fetchCustomers = async () => {
        if (!isAuthenticated) {
            console.log('⚠️ fetchCustomers skipped - not authenticated');
            return;
        }

        console.log('🔄 fetchCustomers called', {
            isAuthenticated,
            userRole: userInfo?.roles?.join(', '),
            hasToken: !!authService.getToken()
        });

        try {
            setLoading(true);
            setError('');

            // Add extra logging to see the actual request
            console.log('📤 Making request to /api/customers...');
            const response = await api.get('/api/customers');
            console.log('📥 Response received:', response.status, response.data);

            // API trả về ApiResponse với cấu trúc {status, data, message}
            // Nên dữ liệu thực sự nằm ở response.data.data
            const customersData = response.data.data || [];
            setCustomers(Array.isArray(customersData) ? customersData : []);
        } catch (err: any) {
            console.error('❌ fetchCustomers error:', err);
            setError(`Failed to fetch customers: ${err.response?.data?.message || err.message}`);
            console.error('Error fetching customers:', err);
            // Set customers về array rỗng khi có lỗi
            setCustomers([]);
        } finally {
            setLoading(false);
        }
    };

    // Tự động gọi hàm fetchCustomers khi component được render lần đầu
    useEffect(() => {
        console.log('📋 CustomerPage useEffect triggered', {
            isAuthenticated,
            hasToken: !!authService.getToken(),
            userInfo: userInfo
        });

        if (isAuthenticated && authService.getToken()) {
            console.log('✅ Conditions met, calling fetchCustomers');
            fetchCustomers();
        } else {
            console.log('⏳ Waiting for authentication...');
        }
    }, [isAuthenticated, userInfo]); // Added userInfo as dependency

    // Show loading while auth is being determined
    if (authLoading) {
        return (
            <div style={{
                padding: '20px',
                textAlign: 'center',
                backgroundColor: '#f5f5f5',
                border: '1px solid #ddd',
                borderRadius: '8px',
                margin: '20px'
            }}>
                <h3>🔄 Đang kiểm tra xác thực...</h3>
                <p>Vui lòng đợi...</p>
            </div>
        );
    }

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
                <p>Vui lòng đăng nhập để truy cập trang quản lý khách hàng.</p>
            </div>
        );
    }

    // Hàm xử lý khi chọn khách hàng
    const handleCustomerSelect = async (customerId: number) => {
        try {
            setLoading(true);
            setError('');
            setSelectedCustomerId(customerId);

            console.log('Fetching accounts for customer ID:', customerId);

            // Gọi API để lấy danh sách tài khoản của khách hàng
            const response = await api.get(`/api/customers/${customerId}/accounts`);
            // AccountController trả về trực tiếp array, không qua ApiResponse wrapper
            const accountsData = response.data;
            console.log('Accounts response:', accountsData);
            setAccounts(Array.isArray(accountsData) ? accountsData : []);
        } catch (err: any) {
            console.error('Full error object:', err);
            console.error('Error response:', err.response);
            setError(`Failed to fetch accounts: ${err.response?.data?.message || err.response?.data || err.message}`);
            console.error('Error fetching accounts:', err);
            // Reset accounts khi có lỗi
            setAccounts([]);
        } finally {
            setLoading(false);
        }
    };

    // Hàm xử lý thêm tài khoản mới
    const handleAddAccount = async (e: React.FormEvent) => {
        e.preventDefault();
        if (!selectedCustomerId) return;

        try {
            setLoading(true);
            setError('');

            // Gọi API để tạo tài khoản mới
            await api.post(`/api/customers/${selectedCustomerId}/accounts`, newAccount);

            // Reset form
            setNewAccount({ accountType: '', balance: 0 });

            // Tải lại danh sách tài khoản
            await handleCustomerSelect(selectedCustomerId);
        } catch (err: any) {
            setError(`Failed to create account: ${err.response?.data?.message || err.message}`);
            console.error('Error creating account:', err);
        } finally {
            setLoading(false);
        }
    };

    // Hàm xử lý xem lịch sử giao dịch
    const handleViewHistory = (account: Account) => {
        if (account.id) {
            setViewingHistoryFor(account);
        } else {
            setError('Cannot view history for account without ID');
        }
    };

    // Hàm đóng modal lịch sử giao dịch
    const handleCloseHistory = () => {
        setViewingHistoryFor(null);
    };

    const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
        const { name, value } = e.target;
        if (editingCustomer) {
            setEditingCustomer({ ...editingCustomer, [name]: value });
        } else {
            setNewCustomer({ ...newCustomer, [name]: value });
        }
    };

    // Hàm xử lý thay đổi input cho form tài khoản
    const handleAccountInputChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
        const { name, value } = e.target;
        setNewAccount({
            ...newAccount,
            [name]: name === 'balance' ? parseFloat(value) || 0 : value
        });
    };

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        try {
            setLoading(true);
            setError('');

            if (editingCustomer) {
                // Update existing customer
                await api.put(`/api/customers/${editingCustomer.id}`, editingCustomer);
                setEditingCustomer(null);
            } else {
                // Create new customer
                await api.post('/api/customers', newCustomer);
                // Reset form
                setNewCustomer({ fullName: '', email: '', phone: '', address: '' });
            }

            await fetchCustomers(); // Tải lại danh sách sau khi thêm mới/cập nhật
        } catch (err: any) {
            setError(`Failed to save customer: ${err.response?.data?.message || err.message}`);
            console.error('Error saving customer:', err);
        } finally {
            setLoading(false);
        }
    };

    const handleEdit = (customer: Customer) => {
        setEditingCustomer(customer);
    };

    const handleCancelEdit = () => {
        setEditingCustomer(null);
    };

    const handleDelete = async (id: number) => {
        if (!window.confirm('Are you sure you want to delete this customer?')) {
            return;
        }

        try {
            setLoading(true);
            setError('');
            await api.delete(`/api/customers/${id}`);
            await fetchCustomers(); // Tải lại danh sách sau khi xóa
        } catch (err: any) {
            setError(`Failed to delete customer: ${err.response?.data?.message || err.message}`);
            console.error('Error deleting customer:', err);
        } finally {
            setLoading(false);
        }
    };

    const currentCustomer = editingCustomer || newCustomer;
    const selectedCustomer = Array.isArray(customers) ? customers.find(c => c.id === selectedCustomerId) : null;

    return (
        <div style={{ padding: '20px', maxWidth: '1200px', margin: '0 auto' }}>
            {/* Debug Component - Remove in production */}
            <TokenDebugComponent />

            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
                <h2>Customer Management</h2>
                <div style={{ fontSize: '14px', color: '#666' }}>
                    Đăng nhập: <strong>{userInfo?.username || 'N/A'}</strong> |
                    Quyền: <strong>{userInfo?.roles?.join(', ') || 'N/A'}</strong>
                    {isAdmin() && <span style={{ color: '#4caf50' }}> (Admin)</span>}
                </div>
            </div>

            {/* Error Display */}
            {error && (
                <div style={{
                    padding: '10px',
                    backgroundColor: '#ffebee',
                    color: '#c62828',
                    borderRadius: '4px',
                    marginBottom: '20px'
                }}>
                    {error}
                </div>
            )}

            {/* Form thêm/chỉnh sửa khách hàng - Chỉ Admin mới thấy */}
            {isAdmin() && (
                <div style={{
                    backgroundColor: '#f5f5f5',
                    padding: '20px',
                    borderRadius: '8px',
                    marginBottom: '30px'
                }}>
                    <h3>{editingCustomer ? 'Edit Customer' : 'Add New Customer'}</h3>
                    <form onSubmit={handleSubmit} style={{ display: 'flex', flexWrap: 'wrap', gap: '10px' }}>
                        <input
                            name="fullName"
                            value={currentCustomer.fullName}
                            onChange={handleInputChange}
                            placeholder="Full Name"
                            required
                            style={{ padding: '8px', minWidth: '200px', borderRadius: '4px', border: '1px solid #ccc' }}
                        />
                        <input
                            name="email"
                            type="email"
                            value={currentCustomer.email}
                            onChange={handleInputChange}
                            placeholder="Email"
                            required
                            style={{ padding: '8px', minWidth: '200px', borderRadius: '4px', border: '1px solid #ccc' }}
                        />
                        <input
                            name="phone"
                            value={currentCustomer.phone}
                            onChange={handleInputChange}
                            placeholder="Phone"
                            style={{ padding: '8px', minWidth: '150px', borderRadius: '4px', border: '1px solid #ccc' }}
                        />
                        <input
                            name="address"
                            value={currentCustomer.address}
                            onChange={handleInputChange}
                            placeholder="Address"
                            style={{ padding: '8px', minWidth: '250px', borderRadius: '4px', border: '1px solid #ccc' }}
                        />
                        <div style={{ display: 'flex', gap: '10px' }}>
                            <button
                                type="submit"
                                disabled={loading}
                                style={{
                                    padding: '8px 16px',
                                    backgroundColor: editingCustomer ? '#1976d2' : '#4caf50',
                                    color: 'white',
                                    border: 'none',
                                    borderRadius: '4px',
                                    cursor: loading ? 'not-allowed' : 'pointer'
                                }}
                            >
                                {loading ? 'Saving...' : (editingCustomer ? 'Update Customer' : 'Add Customer')}
                            </button>
                            {editingCustomer && (
                                <button
                                    type="button"
                                    onClick={handleCancelEdit}
                                    style={{
                                        padding: '8px 16px',
                                        backgroundColor: '#757575',
                                        color: 'white',
                                        border: 'none',
                                        borderRadius: '4px',
                                        cursor: 'pointer'
                                    }}
                                >
                                    Cancel
                                </button>
                            )}
                        </div>
                    </form>
                </div>
            )}

            {/* Bảng hiển thị danh sách khách hàng */}
            <div>
                <h3>Customer List ({Array.isArray(customers) ? customers.length : 0} customers)</h3>
                {loading && <p>Loading...</p>}

                {(!Array.isArray(customers) || customers.length === 0) && !loading ? (
                    <p style={{ textAlign: 'center', color: '#666', fontStyle: 'italic' }}>
                        No customers found. Add your first customer above!
                    </p>
                ) : (
                    <div style={{ overflowX: 'auto' }}>
                        <table style={{
                            width: '100%',
                            borderCollapse: 'collapse',
                            backgroundColor: 'white',
                            boxShadow: '0 2px 4px rgba(0,0,0,0.1)'
                        }}>
                            <thead>
                                <tr style={{ backgroundColor: '#f5f5f5' }}>
                                    <th style={{ padding: '12px', border: '1px solid #ddd', textAlign: 'left' }}>ID</th>
                                    <th style={{ padding: '12px', border: '1px solid #ddd', textAlign: 'left' }}>Full Name</th>
                                    <th style={{ padding: '12px', border: '1px solid #ddd', textAlign: 'left' }}>Email</th>
                                    <th style={{ padding: '12px', border: '1px solid #ddd', textAlign: 'left' }}>Phone</th>
                                    <th style={{ padding: '12px', border: '1px solid #ddd', textAlign: 'left' }}>Address</th>
                                    <th style={{ padding: '12px', border: '1px solid #ddd', textAlign: 'center' }}>Actions</th>
                                </tr>
                            </thead>
                            <tbody>
                                {Array.isArray(customers) && customers.map(customer => (
                                    <tr
                                        key={customer.id}
                                        onClick={() => handleCustomerSelect(customer.id!)}
                                        style={{
                                            backgroundColor: selectedCustomerId === customer.id ? '#e8f5e8' :
                                                editingCustomer?.id === customer.id ? '#e3f2fd' : 'white',
                                            cursor: 'pointer',
                                            transition: 'background-color 0.2s'
                                        }}
                                        onMouseEnter={(e) => {
                                            if (selectedCustomerId !== customer.id && editingCustomer?.id !== customer.id) {
                                                e.currentTarget.style.backgroundColor = '#f5f5f5';
                                            }
                                        }}
                                        onMouseLeave={(e) => {
                                            if (selectedCustomerId !== customer.id && editingCustomer?.id !== customer.id) {
                                                e.currentTarget.style.backgroundColor = 'white';
                                            }
                                        }}
                                    >
                                        <td style={{ padding: '12px', border: '1px solid #ddd' }}>{customer.id}</td>
                                        <td style={{ padding: '12px', border: '1px solid #ddd' }}>
                                            {customer.fullName}
                                            {selectedCustomerId === customer.id && (
                                                <span style={{
                                                    marginLeft: '8px',
                                                    color: '#4caf50',
                                                    fontSize: '12px',
                                                    fontWeight: 'bold'
                                                }}>
                                                    ✓ Selected
                                                </span>
                                            )}
                                        </td>
                                        <td style={{ padding: '12px', border: '1px solid #ddd' }}>{customer.email}</td>
                                        <td style={{ padding: '12px', border: '1px solid #ddd' }}>{customer.phone || '-'}</td>
                                        <td style={{ padding: '12px', border: '1px solid #ddd' }}>{customer.address || '-'}</td>
                                        <td style={{ padding: '12px', border: '1px solid #ddd', textAlign: 'center' }}>
                                            <div style={{ display: 'flex', gap: '5px', justifyContent: 'center' }}>
                                                {/* Chỉ Admin mới có thể Edit */}
                                                {isAdmin() && (
                                                    <button
                                                        onClick={(e) => {
                                                            e.stopPropagation(); // Ngăn chặn event bubbling
                                                            handleEdit(customer);
                                                        }}
                                                        disabled={loading}
                                                        style={{
                                                            padding: '4px 8px',
                                                            backgroundColor: '#1976d2',
                                                            color: 'white',
                                                            border: 'none',
                                                            borderRadius: '3px',
                                                            fontSize: '12px',
                                                            cursor: loading ? 'not-allowed' : 'pointer'
                                                        }}
                                                    >
                                                        Edit
                                                    </button>
                                                )}
                                                {/* Chỉ Admin mới có thể Delete */}
                                                {isAdmin() && (
                                                    <button
                                                        onClick={(e) => {
                                                            e.stopPropagation(); // Ngăn chặn event bubbling
                                                            handleDelete(customer.id!);
                                                        }}
                                                        disabled={loading}
                                                        style={{
                                                            padding: '4px 8px',
                                                            backgroundColor: '#d32f2f',
                                                            color: 'white',
                                                            border: 'none',
                                                            borderRadius: '3px',
                                                            fontSize: '12px',
                                                            cursor: loading ? 'not-allowed' : 'pointer'
                                                        }}
                                                    >
                                                        Delete
                                                    </button>
                                                )}
                                                {/* Hiển thị thông báo nếu không có quyền */}
                                                {!isAdmin() && !hasRole('MANAGER') && (
                                                    <span style={{ fontSize: '12px', color: '#666', fontStyle: 'italic' }}>
                                                        Chỉ xem
                                                    </span>
                                                )}
                                            </div>
                                        </td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    </div>
                )}
            </div>

            {/* Khu vực quản lý tài khoản */}
            {selectedCustomerId && selectedCustomer && (
                <div style={{
                    backgroundColor: '#f9f9f9',
                    padding: '20px',
                    borderRadius: '8px',
                    marginTop: '30px',
                    border: '2px solid #e0e0e0'
                }}>
                    <div style={{
                        display: 'flex',
                        alignItems: 'center',
                        marginBottom: '20px',
                        paddingBottom: '15px',
                        borderBottom: '2px solid #e0e0e0'
                    }}>
                        <h3 style={{ margin: '0', color: '#2e7d32' }}>
                            Accounts for Customer #{selectedCustomerId}
                        </h3>
                        <span style={{
                            marginLeft: '15px',
                            padding: '5px 12px',
                            backgroundColor: '#e8f5e8',
                            color: '#2e7d32',
                            borderRadius: '15px',
                            fontSize: '14px',
                            fontWeight: 'bold'
                        }}>
                            {selectedCustomer.fullName}
                        </span>
                    </div>

                    {/* Form thêm tài khoản mới - Chỉ Admin và Manager */}
                    {(isAdmin() || hasRole('MANAGER')) && (
                        <div style={{
                            backgroundColor: 'white',
                            padding: '20px',
                            borderRadius: '8px',
                            marginBottom: '25px',
                            border: '1px solid #e0e0e0',
                            boxShadow: '0 2px 4px rgba(0,0,0,0.05)'
                        }}>
                            <h4 style={{
                                margin: '0 0 15px 0',
                                color: '#1976d2',
                                display: 'flex',
                                alignItems: 'center'
                            }}>
                                <span style={{
                                    marginRight: '10px',
                                    backgroundColor: '#1976d2',
                                    color: 'white',
                                    borderRadius: '50%',
                                    width: '24px',
                                    height: '24px',
                                    display: 'flex',
                                    alignItems: 'center',
                                    justifyContent: 'center',
                                    fontSize: '14px'
                                }}>
                                    +
                                </span>
                                Add New Account
                            </h4>
                            <form onSubmit={handleAddAccount} style={{ display: 'flex', flexWrap: 'wrap', gap: '15px', alignItems: 'end' }}>
                                <div>
                                    <label style={{
                                        display: 'block',
                                        marginBottom: '8px',
                                        fontSize: '14px',
                                        fontWeight: '500',
                                        color: '#333'
                                    }}>
                                        Account Type: <span style={{ color: '#d32f2f' }}>*</span>
                                    </label>
                                    <select
                                        name="accountType"
                                        value={newAccount.accountType}
                                        onChange={handleAccountInputChange}
                                        required
                                        style={{
                                            padding: '10px',
                                            minWidth: '150px',
                                            borderRadius: '6px',
                                            border: '2px solid #e0e0e0',
                                            fontSize: '14px',
                                            backgroundColor: 'white'
                                        }}
                                    >
                                        <option value="">Select Type</option>
                                        <option value="SAVINGS">💰 Savings</option>
                                        <option value="CHECKING">💳 Checking</option>
                                        <option value="CREDIT">🎯 Credit</option>
                                    </select>
                                </div>
                                <div>
                                    <label style={{
                                        display: 'block',
                                        marginBottom: '8px',
                                        fontSize: '14px',
                                        fontWeight: '500',
                                        color: '#333'
                                    }}>
                                        Initial Balance ($): <span style={{ color: '#d32f2f' }}>*</span>
                                    </label>
                                    <input
                                        name="balance"
                                        type="number"
                                        step="0.01"
                                        min="0"
                                        value={newAccount.balance}
                                        onChange={handleAccountInputChange}
                                        placeholder="0.00"
                                        required
                                        style={{
                                            padding: '10px',
                                            minWidth: '140px',
                                            borderRadius: '6px',
                                            border: '2px solid #e0e0e0',
                                            fontSize: '14px'
                                        }}
                                    />
                                </div>
                                <button
                                    type="submit"
                                    disabled={loading}
                                    style={{
                                        padding: '10px 20px',
                                        backgroundColor: loading ? '#ccc' : '#4caf50',
                                        color: 'white',
                                        border: 'none',
                                        borderRadius: '6px',
                                        cursor: loading ? 'not-allowed' : 'pointer',
                                        fontSize: '14px',
                                        fontWeight: '500',
                                        minHeight: '40px',
                                        display: 'flex',
                                        alignItems: 'center',
                                        gap: '8px'
                                    }}
                                >
                                    {loading ? (
                                        <>
                                            <span>⏳</span>
                                            Creating...
                                        </>
                                    ) : (
                                        <>
                                            <span>➕</span>
                                            Add Account
                                        </>
                                    )}
                                </button>
                            </form>
                        </div>
                    )}

                    {/* Danh sách tài khoản */}
                    <div>
                        <h4 style={{
                            margin: '0 0 15px 0',
                            color: '#1976d2',
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'space-between'
                        }}>
                            <span style={{ display: 'flex', alignItems: 'center' }}>
                                <span style={{
                                    marginRight: '10px',
                                    backgroundColor: '#1976d2',
                                    color: 'white',
                                    borderRadius: '50%',
                                    width: '24px',
                                    height: '24px',
                                    display: 'flex',
                                    alignItems: 'center',
                                    justifyContent: 'center',
                                    fontSize: '14px'
                                }}>
                                    📋
                                </span>
                                Account List
                            </span>
                            <span style={{
                                backgroundColor: '#e3f2fd',
                                color: '#1976d2',
                                padding: '4px 12px',
                                borderRadius: '12px',
                                fontSize: '14px',
                                fontWeight: 'bold'
                            }}>
                                {accounts.length} accounts
                            </span>
                        </h4>
                        {accounts.length === 0 ? (
                            <div style={{
                                textAlign: 'center',
                                padding: '40px',
                                backgroundColor: 'white',
                                borderRadius: '8px',
                                border: '2px dashed #e0e0e0'
                            }}>
                                <div style={{ fontSize: '48px', marginBottom: '10px' }}>🏦</div>
                                <p style={{ color: '#666', fontStyle: 'italic', margin: '0', fontSize: '16px' }}>
                                    No accounts found for this customer
                                </p>
                                <p style={{ color: '#999', margin: '5px 0 0 0', fontSize: '14px' }}>
                                    Add the first account using the form above!
                                </p>
                            </div>
                        ) : (
                            <div style={{ overflowX: 'auto' }}>
                                <table style={{
                                    width: '100%',
                                    borderCollapse: 'collapse',
                                    backgroundColor: 'white',
                                    boxShadow: '0 4px 6px rgba(0,0,0,0.1)',
                                    borderRadius: '8px',
                                    overflow: 'hidden'
                                }}>
                                    <thead>
                                        <tr style={{ backgroundColor: '#f8f9fa' }}>
                                            <th style={{ padding: '15px 12px', border: '1px solid #dee2e6', textAlign: 'left', fontWeight: '600', color: '#495057' }}>Account ID</th>
                                            <th style={{ padding: '15px 12px', border: '1px solid #dee2e6', textAlign: 'left', fontWeight: '600', color: '#495057' }}>Account Number</th>
                                            <th style={{ padding: '15px 12px', border: '1px solid #dee2e6', textAlign: 'left', fontWeight: '600', color: '#495057' }}>Type</th>
                                            <th style={{ padding: '15px 12px', border: '1px solid #dee2e6', textAlign: 'right', fontWeight: '600', color: '#495057' }}>Balance</th>
                                            <th style={{ padding: '15px 12px', border: '1px solid #dee2e6', textAlign: 'center', fontWeight: '600', color: '#495057' }}>Status</th>
                                            <th style={{ padding: '15px 12px', border: '1px solid #dee2e6', textAlign: 'center', fontWeight: '600', color: '#495057' }}>Open Date</th>
                                            <th style={{ padding: '15px 12px', border: '1px solid #dee2e6', textAlign: 'center', fontWeight: '600', color: '#495057' }}>Actions</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        {accounts.map((account, index) => (
                                            <tr key={account.id} style={{
                                                backgroundColor: index % 2 === 0 ? 'white' : '#fafbfc'
                                            }}>
                                                <td style={{ padding: '15px 12px', border: '1px solid #dee2e6', fontSize: '14px' }}>
                                                    #{account.id}
                                                </td>
                                                <td style={{
                                                    padding: '15px 12px',
                                                    border: '1px solid #dee2e6',
                                                    fontFamily: 'Consolas, monospace',
                                                    fontSize: '14px',
                                                    fontWeight: '500',
                                                    color: '#495057'
                                                }}>
                                                    {account.accountNumber}
                                                </td>
                                                <td style={{ padding: '15px 12px', border: '1px solid #dee2e6', fontSize: '14px' }}>
                                                    <span style={{
                                                        padding: '4px 8px',
                                                        borderRadius: '4px',
                                                        fontSize: '12px',
                                                        fontWeight: '500',
                                                        backgroundColor:
                                                            account.accountType === 'SAVINGS' ? '#e8f5e8' :
                                                                account.accountType === 'CHECKING' ? '#e3f2fd' : '#fff3e0',
                                                        color:
                                                            account.accountType === 'SAVINGS' ? '#2e7d32' :
                                                                account.accountType === 'CHECKING' ? '#1976d2' : '#f57c00'
                                                    }}>
                                                        {account.accountType === 'SAVINGS' ? '💰 Savings' :
                                                            account.accountType === 'CHECKING' ? '💳 Checking' : '🎯 Credit'}
                                                    </span>
                                                </td>
                                                <td style={{
                                                    padding: '15px 12px',
                                                    border: '1px solid #dee2e6',
                                                    textAlign: 'right',
                                                    fontWeight: 'bold',
                                                    fontSize: '15px',
                                                    color: account.balance >= 0 ? '#2e7d32' : '#d32f2f'
                                                }}>
                                                    ${account.balance.toLocaleString('en-US', { minimumFractionDigits: 2 })}
                                                </td>
                                                <td style={{ padding: '15px 12px', border: '1px solid #dee2e6', textAlign: 'center' }}>
                                                    <span style={{
                                                        padding: '6px 12px',
                                                        borderRadius: '20px',
                                                        fontSize: '12px',
                                                        fontWeight: '600',
                                                        backgroundColor: account.status === 'ACTIVE' ? '#e8f5e8' : '#fff3cd',
                                                        color: account.status === 'ACTIVE' ? '#2e7d32' : '#856404'
                                                    }}>
                                                        {account.status === 'ACTIVE' ? '✅ ACTIVE' : '⚠️ ' + account.status}
                                                    </span>
                                                </td>
                                                <td style={{
                                                    padding: '15px 12px',
                                                    border: '1px solid #dee2e6',
                                                    textAlign: 'center',
                                                    fontSize: '14px',
                                                    color: '#6c757d'
                                                }}>
                                                    📅 {new Date(account.openDate).toLocaleDateString()}
                                                </td>
                                                <td style={{ padding: '15px 12px', border: '1px solid #dee2e6', textAlign: 'center' }}>
                                                    <button
                                                        onClick={() => handleViewHistory(account)}
                                                        style={{
                                                            background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
                                                            color: 'white',
                                                            border: 'none',
                                                            borderRadius: '6px',
                                                            padding: '8px 16px',
                                                            fontSize: '13px',
                                                            fontWeight: '500',
                                                            cursor: 'pointer',
                                                            transition: 'all 0.2s ease',
                                                            display: 'flex',
                                                            alignItems: 'center',
                                                            gap: '6px',
                                                            margin: '0 auto'
                                                        }}
                                                        onMouseOver={(e) => {
                                                            e.currentTarget.style.transform = 'translateY(-1px)';
                                                            e.currentTarget.style.boxShadow = '0 4px 8px rgba(102, 126, 234, 0.3)';
                                                        }}
                                                        onMouseOut={(e) => {
                                                            e.currentTarget.style.transform = 'translateY(0)';
                                                            e.currentTarget.style.boxShadow = 'none';
                                                        }}
                                                    >
                                                        📊 View History
                                                    </button>
                                                </td>
                                            </tr>
                                        ))}
                                    </tbody>
                                </table>
                            </div>
                        )}
                    </div>
                </div>
            )}

            {/* Transaction History Modal */}
            {viewingHistoryFor && (
                <TransactionHistory
                    account={viewingHistoryFor}
                    onClose={handleCloseHistory}
                />
            )}
        </div>
    );
};