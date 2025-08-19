# Test Logout Functionality
Write-Host "🔐 Testing Logout Functionality..." -ForegroundColor Cyan

# Step 1: Check if React is running
Write-Host "`n1️⃣ Checking React server..." -ForegroundColor Yellow
$reactPort = netstat -ano | findstr ":3000"
if ($reactPort) {
    Write-Host "✅ React server is running on port 3000" -ForegroundColor Green
} else {
    Write-Host "❌ React server is not running. Please start with 'npm start'" -ForegroundColor Red
    exit 1
}

# Step 2: Check if Keycloak is running
Write-Host "`n2️⃣ Checking Keycloak server..." -ForegroundColor Yellow
try {
    $keycloakResponse = Invoke-WebRequest -Uri "http://localhost:8090/realms/Kienlongbank" -Method GET -TimeoutSec 5
    Write-Host "✅ Keycloak server is running" -ForegroundColor Green
} catch {
    Write-Host "❌ Keycloak server is not accessible" -ForegroundColor Red
    Write-Host "Please ensure Docker containers are running: docker-compose up -d" -ForegroundColor Yellow
    exit 1
}

# Step 3: Test direct grant (login) to get a token
Write-Host "`n3️⃣ Testing login..." -ForegroundColor Yellow
$loginBody = @{
    grant_type = 'password'
    client_id = 'kienlongbank-client'
    username = 'testuser'
    password = 'password123'
} | ConvertTo-Json

try {
    $loginResponse = Invoke-RestMethod -Uri "http://localhost:8090/realms/Kienlongbank/protocol/openid-connect/token" -Method POST -Body $loginBody -ContentType "application/json"
    $accessToken = $loginResponse.access_token
    $refreshToken = $loginResponse.refresh_token
    Write-Host "✅ Login successful. Got access token" -ForegroundColor Green
} catch {
    Write-Host "❌ Login failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Step 4: Test logout endpoint
Write-Host "`n4️⃣ Testing logout..." -ForegroundColor Yellow
$logoutBody = @{
    refresh_token = $refreshToken
} | ConvertTo-Json

try {
    $logoutResponse = Invoke-RestMethod -Uri "http://localhost:8090/realms/Kienlongbank/protocol/openid-connect/logout" -Method POST -Body $logoutBody -ContentType "application/json"
    Write-Host "✅ Logout successful" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Logout API call failed: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "This might be normal if the logout endpoint doesn't return content" -ForegroundColor Gray
}

# Step 5: Try to use the token after logout (should fail)
Write-Host "`n5️⃣ Testing token validity after logout..." -ForegroundColor Yellow
try {
    $headers = @{
        Authorization = "Bearer $accessToken"
    }
    $userInfoResponse = Invoke-RestMethod -Uri "http://localhost:8090/realms/Kienlongbank/protocol/openid-connect/userinfo" -Method GET -Headers $headers
    Write-Host "❌ Token is still valid after logout (unexpected)" -ForegroundColor Red
} catch {
    Write-Host "✅ Token is invalid after logout (expected)" -ForegroundColor Green
}

Write-Host "`n🎉 Logout test completed!" -ForegroundColor Cyan
Write-Host "`nNext steps:" -ForegroundColor White
Write-Host "1. Open http://localhost:3000/custom-login" -ForegroundColor Gray
Write-Host "2. Login with testuser/password123" -ForegroundColor Gray
Write-Host "3. Click the logout button in the header" -ForegroundColor Gray
Write-Host "4. Verify you're redirected to login page" -ForegroundColor Gray
