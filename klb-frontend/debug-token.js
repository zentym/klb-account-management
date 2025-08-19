// Debug script để kiểm tra token trong browser console
// Chạy script này trong browser console sau khi login

console.log('=== TOKEN DEBUG REPORT ===');

// 1. Kiểm tra localStorage
console.log('1. localStorage tokens:');
console.log('   jwtToken:', localStorage.getItem('jwtToken'));
console.log('   username:', localStorage.getItem('username'));
console.log('   user:', localStorage.getItem('user'));

// 2. Kiểm tra sessionStorage  
console.log('2. sessionStorage tokens:');
console.log('   jwtToken:', sessionStorage.getItem('jwtToken'));
console.log('   username:', sessionStorage.getItem('username'));
console.log('   user:', sessionStorage.getItem('user'));

// 3. Kiểm tra axios defaults
console.log('3. Axios defaults:');
console.log('   Authorization header:', window.axios?.defaults?.headers?.common?.Authorization);

// 4. Test API call với logging
console.log('4. Testing API call...');
fetch('/api/health', {
    method: 'GET',
    headers: {
        'Authorization': `Bearer ${localStorage.getItem('jwtToken') || sessionStorage.getItem('jwtToken')}`,
        'Content-Type': 'application/json'
    }
})
    .then(response => {
        console.log('   API Response status:', response.status);
        return response.json();
    })
    .then(data => console.log('   API Response data:', data))
    .catch(error => console.error('   API Error:', error));

console.log('=== END DEBUG REPORT ===');
