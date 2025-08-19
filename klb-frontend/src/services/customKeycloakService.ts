import axios from 'axios';
import { jwtDecode } from 'jwt-decode';

interface LoginResponse {
    access_token: string;
    refresh_token: string;
    token_type: string;
    expires_in: number;
}

interface JwtPayload {
    preferred_username?: string;
    email?: string;
    name?: string;
    realm_access?: {
        roles: string[];
    };
    exp?: number;
    iat?: number;
    sub?: string;
}

interface UserInfo {
    username: string;
    email?: string;
    name?: string;
    roles: string[];
    token: string;
    refreshToken: string;
}

class CustomKeycloakService {
    private keycloakUrl = 'http://localhost:8090'; // Always use direct URL for admin API
    private realm = 'master'; // Use master realm since Kienlongbank doesn't exist yet
    private clientId = 'admin-cli'; // Use admin-cli client for admin API
    private adminCredentials = {
        username: 'admin',
        password: 'admin'
    };

    /**
     * 📝 Register new user with Keycloak Admin API
     * Creates user account and sets password
     */
    async register(phoneNumber: string, password: string, firstName: string = '', email: string = ''): Promise<UserInfo> {
        try {
            console.log('🔐 Starting Keycloak registration process...');
            console.log('📋 Registration data:', { phoneNumber, firstName, email });

            // Step 1: Get admin token
            console.log('🔑 Getting admin token...');
            const adminToken = await this.getAdminToken();
            console.log('✅ Admin token obtained');

            // Step 2: Create user
            console.log('👤 Creating user in Keycloak...');
            const userId = await this.createUser(adminToken, phoneNumber, firstName, email);
            console.log('✅ User created with ID:', userId);

            // Step 3: Set user password  
            console.log('🔒 Setting user password...');
            await this.setUserPassword(adminToken, userId, password);
            console.log('✅ Password set for user');

            // Step 4: Login as the new user to get tokens
            console.log('🔐 Logging in as new user...');
            const userInfo = await this.login(phoneNumber, password);
            console.log('✅ New user logged in successfully');

            return userInfo;

        } catch (error: any) {
            console.error('❌ Registration failed:', error);
            console.error('❌ Error details:', {
                status: error.response?.status,
                statusText: error.response?.statusText,
                data: error.response?.data,
                message: error.message
            });

            // More specific error handling
            if (error.response?.status === 409) {
                throw new Error('Số điện thoại này đã được đăng ký. Vui lòng sử dụng số khác.');
            } else if (error.response?.status === 401) {
                throw new Error('Lỗi xác thực với Keycloak. Vui lòng kiểm tra cấu hình admin.');
            } else if (error.response?.status === 403) {
                throw new Error('Không có quyền tạo user. Vui lòng kiểm tra quyền admin.');
            } else if (error.response?.status === 400) {
                const errorMsg = error.response?.data?.errorMessage || error.response?.data?.error_description;
                throw new Error(`Dữ liệu không hợp lệ: ${errorMsg || 'Vui lòng kiểm tra thông tin đăng ký'}`);
            } else if (error.message?.includes('Tài khoản không hợp lệ')) {
                // This is from the login step - user created but login failed
                throw new Error('Tài khoản đã được tạo nhưng đăng nhập thất bại. Vui lòng thử đăng nhập trực tiếp.');
            } else {
                throw new Error(`Lỗi đăng ký: ${error.message}`);
            }
        }
    }

    /**
     * 🔑 Get admin access token for Keycloak Admin API
     */
    private async getAdminToken(): Promise<string> {
        const tokenUrl = this.keycloakUrl
            ? `${this.keycloakUrl}/realms/master/protocol/openid-connect/token`
            : `/realms/master/protocol/openid-connect/token`;

        console.log('🔗 Admin token URL:', tokenUrl);
        console.log('🔑 Admin credentials:', { username: this.adminCredentials.username, password: '***' });

        try {
            const response = await axios.post<LoginResponse>(
                tokenUrl,
                new URLSearchParams({
                    grant_type: 'password',
                    client_id: 'admin-cli',
                    username: this.adminCredentials.username,
                    password: this.adminCredentials.password,
                }),
                {
                    headers: {
                        'Content-Type': 'application/x-www-form-urlencoded',
                    },
                    timeout: 10000 // 10 second timeout
                }
            );

            if (!response.data.access_token) {
                throw new Error('No access token received from Keycloak');
            }

            console.log('✅ Admin token response received');
            return response.data.access_token;

        } catch (error: any) {
            console.error('❌ Failed to get admin token:', error);
            if (error.code === 'ECONNREFUSED') {
                throw new Error('Không thể kết nối đến Keycloak. Vui lòng kiểm tra Keycloak đang chạy trên port 8090.');
            } else if (error.response?.status === 401) {
                throw new Error('Sai thông tin admin Keycloak. Vui lòng kiểm tra username/password admin.');
            } else if (error.response?.status === 400) {
                throw new Error('Yêu cầu không hợp lệ đến Keycloak master realm.');
            } else {
                throw new Error(`Lỗi kết nối Keycloak: ${error.message}`);
            }
        }
    }

    /**
     * 👤 Create user in Keycloak
     */
    private async createUser(adminToken: string, phoneNumber: string, firstName: string, email: string): Promise<string> {
        const userUrl = `${this.keycloakUrl}/admin/realms/${this.realm}/users`;
        console.log('👤 Create user URL:', userUrl);

        const userData = {
            username: phoneNumber,
            firstName: firstName || phoneNumber,
            lastName: '',
            email: email || `${phoneNumber}@klb-demo.com`,
            emailVerified: true,
            enabled: true,
            attributes: {
                phoneNumber: [phoneNumber]
            }
        };

        console.log('👤 User data:', { ...userData, password: '***' });

        try {
            const response = await axios.post(userUrl, userData, {
                headers: {
                    'Authorization': `Bearer ${adminToken}`,
                    'Content-Type': 'application/json',
                },
                timeout: 10000
            });

            console.log('✅ User creation response:', response.status);

            // Extract user ID from Location header
            const location = response.headers.location;
            console.log('📍 Location header:', location);

            const userId = location?.split('/').pop();

            if (!userId) {
                throw new Error('Failed to get user ID from response');
            }

            return userId;

        } catch (error: any) {
            console.error('❌ User creation failed:', error);
            if (error.response?.status === 409) {
                throw new Error('User already exists with this phone number');
            } else if (error.response?.status === 400) {
                const errorMsg = error.response?.data?.errorMessage;
                throw new Error(`Invalid user data: ${errorMsg || 'Check user information'}`);
            } else {
                throw error;
            }
        }
    }

    /**
     * 🔒 Set password for user
     */
    private async setUserPassword(adminToken: string, userId: string, password: string): Promise<void> {
        const passwordUrl = `${this.keycloakUrl}/admin/realms/${this.realm}/users/${userId}/reset-password`;
        console.log('🔒 Set password URL:', passwordUrl);

        try {
            await axios.put(passwordUrl, {
                type: 'password',
                value: password,
                temporary: false
            }, {
                headers: {
                    'Authorization': `Bearer ${adminToken}`,
                    'Content-Type': 'application/json',
                },
                timeout: 10000
            });

            console.log('✅ Password set successfully');

        } catch (error: any) {
            console.error('❌ Set password failed:', error);
            throw error;
        }
    }

    /**
     * 🔐 Custom login with username/password (Direct Grant)
     * Uses Keycloak's Resource Owner Password Credentials Grant
     */
    async login(username: string, password: string): Promise<UserInfo> {
        try {
            // Always use direct URL for login
            const tokenUrl = `${this.keycloakUrl}/realms/${this.realm}/protocol/openid-connect/token`;
            console.log('🔐 Login URL:', tokenUrl);

            const response = await axios.post<LoginResponse>(
                tokenUrl,
                new URLSearchParams({
                    grant_type: 'password',
                    client_id: this.clientId,
                    username,
                    password,
                }),
                {
                    headers: {
                        'Content-Type': 'application/x-www-form-urlencoded',
                    },
                    timeout: 10000
                }
            );

            console.log('✅ Login response received');
            const { access_token, refresh_token } = response.data;

            // Decode JWT to extract user information
            const decoded: JwtPayload = jwtDecode(access_token);

            const userInfo: UserInfo = {
                username: decoded.preferred_username || username,
                email: decoded.email,
                name: decoded.name,
                roles: decoded.realm_access?.roles || [],
                token: access_token,
                refreshToken: refresh_token,
            };

            // Store in localStorage for persistence
            localStorage.setItem('klb_user_info', JSON.stringify(userInfo));
            localStorage.setItem('klb_access_token', access_token);
            localStorage.setItem('klb_refresh_token', refresh_token);

            return userInfo;
        } catch (error) {
            if (axios.isAxiosError(error)) {
                const status = error.response?.status;
                const errorData = error.response?.data;

                switch (status) {
                    case 401:
                        throw new Error('Tên đăng nhập hoặc mật khẩu không đúng');
                    case 400:
                        if (errorData?.error === 'invalid_grant') {
                            throw new Error('Tài khoản không hợp lệ hoặc đã bị khóa');
                        }
                        throw new Error('Dữ liệu đầu vào không hợp lệ');
                    default:
                        throw new Error('Không thể kết nối đến máy chủ xác thực');
                }
            }
            throw new Error('Đã xảy ra lỗi không xác định');
        }
    }

    /**
     * 🔄 Refresh access token
     */
    async refreshToken(): Promise<string> {
        const refreshToken = localStorage.getItem('klb_refresh_token');

        if (!refreshToken) {
            throw new Error('No refresh token available');
        }

        try {
            const response = await axios.post<LoginResponse>(
                `${this.keycloakUrl}/realms/${this.realm}/protocol/openid-connect/token`,
                new URLSearchParams({
                    grant_type: 'refresh_token',
                    client_id: this.clientId,
                    refresh_token: refreshToken,
                }),
                {
                    headers: {
                        'Content-Type': 'application/x-www-form-urlencoded',
                    },
                }
            );

            const { access_token, refresh_token: new_refresh_token } = response.data;

            // Update stored tokens
            localStorage.setItem('klb_access_token', access_token);
            if (new_refresh_token) {
                localStorage.setItem('klb_refresh_token', new_refresh_token);
            }

            return access_token;
        } catch (error) {
            // Refresh failed, user needs to login again
            this.logout();
            throw new Error('Session expired. Please login again.');
        }
    }

    /**
     * 📤 Logout user
     */
    async logout(): Promise<void> {
        const token = localStorage.getItem('klb_access_token');

        // Call Keycloak logout endpoint
        if (token) {
            try {
                await axios.post(
                    `${this.keycloakUrl}/realms/${this.realm}/protocol/openid-connect/logout`,
                    new URLSearchParams({
                        client_id: this.clientId,
                        refresh_token: localStorage.getItem('klb_refresh_token') || '',
                    }),
                    {
                        headers: {
                            'Content-Type': 'application/x-www-form-urlencoded',
                            'Authorization': `Bearer ${token}`,
                        },
                    }
                );
            } catch (error) {
                console.warn('Failed to logout from Keycloak:', error);
            }
        }

        // Clear local storage
        localStorage.removeItem('klb_user_info');
        localStorage.removeItem('klb_access_token');
        localStorage.removeItem('klb_refresh_token');
    }

    /**
     * 👤 Get current user info
     */
    getCurrentUser(): UserInfo | null {
        const userInfoStr = localStorage.getItem('klb_user_info');
        if (!userInfoStr) return null;

        try {
            const userInfo: UserInfo = JSON.parse(userInfoStr);

            // Check if token is expired
            const decoded: JwtPayload = jwtDecode(userInfo.token);
            const now = Date.now() / 1000;

            if (decoded.exp && decoded.exp < now) {
                // Token expired, try refresh
                this.refreshToken().catch(() => {
                    this.logout();
                });
                return null;
            }

            return userInfo;
        } catch (error) {
            console.error('Error parsing user info:', error);
            this.logout();
            return null;
        }
    }

    /**
     * ✅ Check if user is authenticated
     */
    isAuthenticated(): boolean {
        return this.getCurrentUser() !== null;
    }

    /**
     * 🔑 Get current access token
     */
    getToken(): string | null {
        return localStorage.getItem('klb_access_token');
    }

    /**
     * 👑 Check if user has specific role
     */
    hasRole(role: string): boolean {
        const user = this.getCurrentUser();
        return user ? user.roles.includes(role) : false;
    }

    /**
     * 🛡️ Check if user is admin
     */
    isAdmin(): boolean {
        return this.hasRole('admin') || this.hasRole('ADMIN');
    }

    /**
     * 👨‍💼 Get user roles
     */
    getUserRoles(): string[] {
        const user = this.getCurrentUser();
        return user ? user.roles : [];
    }
}

// Export singleton instance
export const customKeycloakService = new CustomKeycloakService();
export default customKeycloakService;
