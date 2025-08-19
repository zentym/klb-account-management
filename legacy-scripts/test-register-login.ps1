# Test tạo user và đăng nhập
Write-Host "🔐 Testing User Registration and Login" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan

$baseUrl = "http://localhost:8080"

# Tạo user mới
$registerData = @{
    username = "testuser"
    password = "testpass123"
} | ConvertTo-Json

Write-Host "📡 Registering new user: testuser/testpass123" -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/api/auth/register" -Method POST -ContentType "application/json" -Body $registerData -UseBasicParsing
    Write-Host "✅ Registration successful!" -ForegroundColor Green
    Write-Host "Message: $($response.message)" -ForegroundColor Cyan
} catch {
    Write-Host "❌ Registration failed: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response.StatusCode -eq 400) {
        Write-Host "Có thể user đã tồn tại, thử đăng nhập..." -ForegroundColor Yellow
    }
}

# Thử đăng nhập với user vừa tạo
Write-Host "`n📡 Trying to login with testuser/testpass123" -ForegroundColor Yellow
try {
    $loginData = @{
        username = "testuser"
        password = "testpass123"
    } | ConvertTo-Json
    
    $response = Invoke-RestMethod -Uri "$baseUrl/api/auth/login" -Method POST -ContentType "application/json" -Body $loginData -UseBasicParsing
    Write-Host "✅ Login successful!" -ForegroundColor Green
    Write-Host "Token: $($response.token)" -ForegroundColor Cyan
    Write-Host "Message: $($response.message)" -ForegroundColor Cyan
    
    # Test API với token này
    $headers = @{
        "Authorization" = "Bearer $($response.token)"
        "Content-Type" = "application/json"
    }
    
    Write-Host "`n📡 Testing customers API with token" -ForegroundColor Yellow
    $customersResponse = Invoke-RestMethod -Uri "$baseUrl/api/customers" -Headers $headers -UseBasicParsing
    Write-Host "✅ Customers API works with token!" -ForegroundColor Green
    Write-Host "Number of customers: $($customersResponse.data.Length)" -ForegroundColor Cyan
    
} catch {
    Write-Host "❌ Login failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n🏁 Test completed!" -ForegroundColor Cyan
