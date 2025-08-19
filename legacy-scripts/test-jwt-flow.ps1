# Test JWT Authentication Flow

Write-Host "Testing JWT Authentication Flow with Enhanced Logging" -ForegroundColor Green

# 1. Register a test user
Write-Host "`n1. Registering test user..." -ForegroundColor Yellow
$registerResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/auth/register" -Method POST -Headers @{"Content-Type"="application/json"} -Body '{"username":"testuser123","password":"testpass123","role":"CUSTOMER"}'
Write-Host "Register Response: $($registerResponse | ConvertTo-Json)"

# 2. Login to get token
Write-Host "`n2. Logging in to get JWT token..." -ForegroundColor Yellow
$loginResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/auth/login" -Method POST -Headers @{"Content-Type"="application/json"} -Body '{"username":"testuser123","password":"testpass123"}'
Write-Host "Login Response: $($loginResponse | ConvertTo-Json)"

$token = $loginResponse.token
Write-Host "JWT Token: $token" -ForegroundColor Cyan

# 3. Test API call with token
Write-Host "`n3. Making API call to /api/customers with JWT token..." -ForegroundColor Yellow
try {
    $customersResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/customers" -Method GET -Headers @{"Authorization"="Bearer $token"}
    Write-Host "Customers Response: $($customersResponse | ConvertTo-Json)"
} catch {
    Write-Host "Error calling /api/customers: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Response: $($_.ErrorDetails.Message)" -ForegroundColor Red
}

# 4. Check logs
Write-Host "`n4. Checking recent logs from main-app..." -ForegroundColor Yellow
docker logs klb-account-management --tail 50
