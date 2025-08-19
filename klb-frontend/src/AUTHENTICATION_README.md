# JWT Authentication with Role-Based Access Control

This documentation explains how to use the updated authentication system in the KLB Account Management frontend application.

## Overview

The authentication system now supports:
- JWT token decoding and validation
- Role-based access control
- Persistent user information storage
- TypeScript type safety

The authentication system consists of:
- **AuthService**: Enhanced service class with role-based methods
- **API Configuration**: Axios configuration with automatic JWT token handling
- **AuthProvider**: React context with role information
- **Login/Register Pages**: UI components for user authentication
- **Role-Based Components**: Examples and utilities for access control

## Files Created

```
src/
├── services/
│   └── authService.ts          # Enhanced authentication service with JWT decoding and role support
├── config/
│   └── api.ts                  # Axios configuration with interceptors
├── components/
│   ├── AuthProvider.tsx        # React context with role information
│   ├── LoginPage.tsx           # Login form component
│   ├── RegisterPage.tsx        # Registration form component
│   ├── AuthServiceExample.tsx  # Example usage (demo)
│   └── RoleBasedExample.tsx    # Role-based access control demo
├── types/
│   └── auth.types.ts           # TypeScript definitions for auth system
└── App-with-auth.tsx           # Example App with authentication flow
```

## Key Features

### 1. JWT Token Decoding
When a user logs in, the JWT token is automatically decoded to extract user information including the role.

### 2. Role-Based Access Control
The system supports checking user roles and permissions for conditional rendering and access control.

### 3. Persistent Storage
User information is stored in localStorage/sessionStorage based on the "Remember Me" preference.

## New Authentication Methods

The `authService` now includes additional methods for role-based access:

```typescript
// Get full user information (includes role)
const userInfo = authService.getUserInfo();
// Returns: { username: string, role: string } | null

// Get user role
const userRole = authService.getUserRole();
// Returns: string | null

// Check specific role
const isAdmin = authService.hasRole('ADMIN');
const isUser = authService.hasRole('USER');

// Convenience method for admin check
const hasAdminAccess = authService.isAdmin();
```

## Updated Login Process

The login method now supports the "Remember Me" feature and automatically handles JWT decoding:

```typescript
// Login with remember me option (default: true)
const handleLogin = async (username: string, password: string, rememberMe: boolean = true) => {
    try {
        const response = await authService.login(username, password, rememberMe);
        
        // User info is automatically extracted and stored
        const userInfo = authService.getUserInfo();
        console.log('Logged in user:', userInfo);
        
        // Redirect based on role
        if (authService.isAdmin()) {
            window.location.href = '/admin/dashboard';
        } else {
            window.location.href = '/dashboard';
        }
        
    } catch (error) {
        console.error('Login failed:', error);
    }
};
```

## Role-Based Component Example

```typescript
import React from 'react';
import { useAuth } from '../components/AuthProvider';

const MyComponent: React.FC = () => {
    const { isAuthenticated, userInfo, hasRole, isAdmin } = useAuth();

    if (!isAuthenticated) {
        return <div>Please log in</div>;
    }

    return (
        <div>
            <h1>Welcome, {userInfo?.username}!</h1>
            <p>Your role: {userInfo?.role}</p>
            
            {/* Admin-only content */}
            {isAdmin() && (
                <div>
                    <h2>Admin Panel</h2>
                    <button>Manage Users</button>
                    <button>System Settings</button>
                </div>
            )}
            
            {/* User content */}
            {hasRole('USER') && (
                <div>
                    <h2>User Dashboard</h2>
                    <button>View Profile</button>
                </div>
            )}
        </div>
    );
};
```

## JWT Token Structure

The system expects JWT tokens with the following payload structure:

```json
{
  "sub": "username",
  "role": "ADMIN",
  "iat": 1640995200,
  "exp": 1641081600
}
```

## Supported Roles

- `ADMIN`: Full system access
- `USER`: Standard user features

## How to Use

### 1. AuthService Methods

```typescript
import { authService } from './services/authService';

// Register a new user
try {
    const result = await authService.register('username', 'password');
    console.log('Registration successful:', result);
} catch (error) {
    console.error('Registration failed:', error.message);
}

// Login user
try {
    const result = await authService.login('username', 'password');
    console.log('Login successful:', result);
    // Token is automatically saved to localStorage
} catch (error) {
    console.error('Login failed:', error.message);
}

// Check if user is authenticated
const isAuthenticated = authService.isAuthenticated();
const currentUser = authService.getCurrentUser();
const token = authService.getToken();

// Logout user
authService.logout(); // Clears all stored tokens
```

### 2. Making API Calls

```typescript
import api from './config/api';

// The JWT token is automatically added to all requests
try {
    // GET request
    const customers = await api.get('/api/customers');
    
    // POST request
    const newCustomer = await api.post('/api/customers', {
        fullName: 'John Doe',
        email: 'john@example.com'
    });
    
    // PUT request
    const updatedCustomer = await api.put('/api/customers/1', customerData);
    
    // DELETE request
    await api.delete('/api/customers/1');
} catch (error) {
    console.error('API call failed:', error);
}
```

### 3. Using AuthProvider

```typescript
// Wrap your app with AuthProvider
import { AuthProvider } from './components/AuthProvider';

function App() {
    return (
        <AuthProvider>
            <YourAppContent />
        </AuthProvider>
    );
}

// Use auth state in components
import { useAuth } from './components/AuthProvider';

function SomeComponent() {
    const { isAuthenticated, user, logout } = useAuth();
    
    if (!isAuthenticated) {
        return <LoginPage />;
    }
    
    return (
        <div>
            <p>Welcome, {user}!</p>
            <button onClick={logout}>Logout</button>
        </div>
    );
}
```

### 4. Using Login/Register Components

```typescript
import LoginPage from './components/LoginPage';
import RegisterPage from './components/RegisterPage';

function AuthFlow() {
    const [showRegister, setShowRegister] = useState(false);
    
    const handleLoginSuccess = (token: string, username: string) => {
        console.log('User logged in:', username);
        // Navigate to main app or update state
    };
    
    const handleRegisterSuccess = () => {
        setShowRegister(false); // Switch back to login
    };
    
    return showRegister ? (
        <RegisterPage
            onRegisterSuccess={handleRegisterSuccess}
            onSwitchToLogin={() => setShowRegister(false)}
        />
    ) : (
        <LoginPage
            onLoginSuccess={handleLoginSuccess}
            onSwitchToRegister={() => setShowRegister(true)}
        />
    );
}
```

## Key Features

### 🔐 Automatic Token Management
- JWT tokens are automatically saved to localStorage/sessionStorage
- Tokens are automatically added to all API requests via interceptors
- Token expiration is checked automatically

### 🔄 Request/Response Interceptors
- **Request Interceptor**: Adds `Authorization: Bearer <token>` header
- **Response Interceptor**: Handles common HTTP errors (401, 403, 500, etc.)
- Automatic logout on 401 Unauthorized responses

### 📱 Storage Management
- **localStorage**: For "Remember Me" functionality (persistent)
- **sessionStorage**: For session-only login
- Automatic cleanup on logout

### 🛡️ Error Handling
- Structured error responses with meaningful messages
- Network error detection
- Validation error handling

## Configuration

### Environment Variables
Update your API base URL if needed in `config/api.ts`:

```typescript
const API_CONFIG = {
    baseURL: process.env.REACT_APP_API_URL || '/',
    timeout: 10000,
};
```

### Backend Requirements

Your backend should provide these endpoints:

```
POST /api/auth/register
Body: { username: string, password: string }
Response: { token: string, username: string }

POST /api/auth/login  
Body: { username: string, password: string }
Response: { token: string, username: string }

GET /api/health
Response: { status: string }
```

## Security Notes

⚠️ **Important Security Considerations:**

1. **HTTPS Only**: Always use HTTPS in production
2. **Token Expiration**: Implement proper JWT expiration on backend
3. **Refresh Tokens**: Consider implementing refresh token mechanism
4. **CORS**: Configure CORS properly on backend
5. **Content Security Policy**: Implement CSP headers
6. **Logout Everywhere**: Consider implementing server-side token blacklisting

## Migration from Direct Axios

If you're updating existing code that uses `axios` directly:

### Before:
```typescript
import axios from 'axios';

const response = await axios.get('/api/customers', {
    headers: {
        'Authorization': `Bearer ${localStorage.getItem('token')}`
    }
});
```

### After:
```typescript
import api from './config/api';

// Token is automatically added by interceptor
const response = await api.get('/api/customers');
```

## Error Handling Examples

```typescript
try {
    await authService.login(username, password);
} catch (error) {
    switch (error.status) {
        case 401:
            setError('Invalid username or password');
            break;
        case 403:
            setError('Account is locked');
            break;
        case 422:
            setError('Please check your input');
            break;
        default:
            setError(error.message || 'Login failed');
    }
}
```

## Testing

You can test the authentication system using the provided `AuthServiceExample` component:

```typescript
import AuthServiceExample from './components/AuthServiceExample';

// Add to your app temporarily for testing
<AuthServiceExample />
```

This example component provides buttons to test all authentication functions and API calls.
