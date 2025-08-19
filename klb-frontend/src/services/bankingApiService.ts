import axios from 'axios';
import customKeycloakService from './customKeycloakService';

// API Base URL - use proxy in development
const API_BASE_URL = process.env.NODE_ENV === 'development' ? '' : 'http://localhost:8080';

// Account & Transaction interfaces
interface Account {
    id: string;
    accountNumber: string;
    accountType: string;
    balance: number;
    currency: string;
    status: string;
}

interface Transaction {
    id: string;
    accountNumber: string;
    amount: number;
    type: 'DEBIT' | 'CREDIT';
    description: string;
    timestamp: string;
    balance?: number;
}

interface Customer {
    id: string;
    firstName: string;
    lastName: string;
    email: string;
    phoneNumber: string;
    address?: string;
    createdAt: string;
    updatedAt: string;
}

class BankingApiService {

    /**
     * Get authenticated API headers
     */
    private getAuthHeaders() {
        const token = customKeycloakService.getToken();
        return {
            'Authorization': `Bearer ${token}`,
            'Content-Type': 'application/json'
        };
    }

    /**
     * 👤 Get customer information
     */
    async getCustomerInfo(): Promise<Customer | null> {
        try {
            const response = await axios.get(`${API_BASE_URL}/api/customers/me`, {
                headers: this.getAuthHeaders()
            });
            return response.data;
        } catch (error: any) {
            console.error('❌ Failed to get customer info:', error);
            if (error.response?.status === 401) {
                throw new Error('Authentication required');
            }
            return null;
        }
    }

    /**
     * 🏦 Get user accounts
     */
    async getAccounts(): Promise<Account[]> {
        try {
            const response = await axios.get(`${API_BASE_URL}/api/accounts`, {
                headers: this.getAuthHeaders()
            });
            return response.data;
        } catch (error: any) {
            console.error('❌ Failed to get accounts:', error);
            if (error.response?.status === 401) {
                throw new Error('Authentication required');
            }
            return [];
        }
    }

    /**
     * 📊 Get account transactions
     */
    async getTransactions(accountNumber?: string, limit: number = 10): Promise<Transaction[]> {
        try {
            let url = `${API_BASE_URL}/api/transactions?limit=${limit}`;
            if (accountNumber) {
                url += `&accountNumber=${accountNumber}`;
            }

            const response = await axios.get(url, {
                headers: this.getAuthHeaders()
            });
            return response.data;
        } catch (error: any) {
            console.error('❌ Failed to get transactions:', error);
            if (error.response?.status === 401) {
                throw new Error('Authentication required');
            }
            return [];
        }
    }

    /**
     * 💸 Create transfer transaction
     */
    async createTransfer(fromAccount: string, toAccount: string, amount: number, description: string): Promise<Transaction> {
        try {
            const response = await axios.post(`${API_BASE_URL}/api/transactions`, {
                fromAccountNumber: fromAccount,
                toAccountNumber: toAccount,
                amount: amount,
                description: description,
                type: 'TRANSFER'
            }, {
                headers: this.getAuthHeaders()
            });
            return response.data;
        } catch (error: any) {
            console.error('❌ Failed to create transfer:', error);
            if (error.response?.status === 401) {
                throw new Error('Authentication required');
            }
            throw error;
        }
    }

    /**
     * 🏦 Create new account
     */
    async createAccount(accountType: string = 'SAVINGS'): Promise<Account> {
        try {
            const response = await axios.post(`${API_BASE_URL}/api/accounts`, {
                accountType: accountType,
                currency: 'VND'
            }, {
                headers: this.getAuthHeaders()
            });
            return response.data;
        } catch (error: any) {
            console.error('❌ Failed to create account:', error);
            if (error.response?.status === 401) {
                throw new Error('Authentication required');
            }
            throw error;
        }
    }

    /**
     * ✅ Health check
     */
    async healthCheck(): Promise<boolean> {
        try {
            const response = await axios.get(`${API_BASE_URL}/api/health`, {
                timeout: 5000
            });
            return response.status === 200;
        } catch (error) {
            console.warn('⚠️ Backend health check failed:', error);
            return false;
        }
    }
}

// Export singleton instance
export const bankingApiService = new BankingApiService();
export default bankingApiService;
