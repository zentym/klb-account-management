// Debug Token Script - Chạy trong browser console
// Copy và paste toàn bộ script này vào browser console

console.log('🔧 === DETAILED TOKEN DEBUG ===');

// 1. Kiểm tra tất cả storage
console.log('📦 1. Storage Check:');
const localToken = localStorage.getItem('jwtToken');
const sessionToken = sessionStorage.getItem('jwtToken');
const localUser = localStorage.getItem('username');
const sessionUser = sessionStorage.getItem('username');

console.log('   localStorage jwtToken:', localToken ? localToken.substring(0, 50) + '...' : 'NOT FOUND');
console.log('   sessionStorage jwtToken:', sessionToken ? sessionToken.substring(0, 50) + '...' : 'NOT FOUND');
console.log('   localStorage username:', localUser);
console.log('   sessionStorage username:', sessionUser);

// 2. Decode token để kiểm tra validity
console.log('\n🔍 2. Token Analysis:');
const activeToken = localToken || sessionToken;
if (activeToken) {
    try {
        // Decode JWT payload
        const base64Url = activeToken.split('.')[1];
        const base64 = base64Url.replace(/-/g, '+').replace(/_/g, '/');
        const jsonPayload = decodeURIComponent(
            atob(base64)
                .split('')
                .map(c => '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2))
                .join('')
        );
        const payload = JSON.parse(jsonPayload);

        console.log('   Token payload:', payload);
        console.log('   Token issued at:', new Date(payload.iat * 1000));
        console.log('   Token expires at:', new Date(payload.exp * 1000));
        console.log('   Current time:', new Date());
        console.log('   Is expired?', payload.exp < Date.now() / 1000);

    } catch (error) {
        console.error('   ❌ Token decode error:', error);
    }
} else {
    console.log('   ❌ No token found in storage');
}

// 3. Test manual API call
console.log('\n🧪 3. Manual API Test:');
if (activeToken) {
    fetch('/api/customers', {
        method: 'GET',
        headers: {
            'Authorization': `Bearer ${activeToken}`,
            'Content-Type': 'application/json'
        }
    })
        .then(response => {
            console.log('   Response status:', response.status);
            console.log('   Response headers:', [...response.headers.entries()]);
            if (response.status === 401) {
                console.log('   ❌ 401 Unauthorized - Token rejected by server');
            }
            return response.text();
        })
        .then(data => {
            console.log('   Response body:', data);
        })
        .catch(error => {
            console.error('   ❌ Network error:', error);
        });
} else {
    console.log('   ⚠️ Cannot test - no token available');
}

// 4. Check backend connectivity
console.log('\n🌐 4. Backend Connectivity:');
fetch('/api/health', {
    method: 'GET',
    headers: {
        'Content-Type': 'application/json'
    }
})
    .then(response => {
        console.log('   Health check status:', response.status);
        return response.json();
    })
    .then(data => {
        console.log('   Health check data:', data);
    })
    .catch(error => {
        console.error('   ❌ Backend not reachable:', error);
    });

// 5. Check authentication endpoint
console.log('\n🔐 5. Auth Endpoint Test:');
if (localUser || sessionUser) {
    // Test if we can refresh/validate token
    fetch('/api/auth/validate', {
        method: 'POST',
        headers: {
            'Authorization': `Bearer ${activeToken}`,
            'Content-Type': 'application/json'
        }
    })
        .then(response => {
            console.log('   Token validation status:', response.status);
            return response.json();
        })
        .then(data => {
            console.log('   Token validation result:', data);
        })
        .catch(error => {
            console.log('   Token validation failed:', error);
        });
}

console.log('\n🔧 === END DEBUG ===');
