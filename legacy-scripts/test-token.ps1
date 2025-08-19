# Test login và sử dụng token
Write-Host "🔐 Testing Login and Token Usage" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan

$baseUrl = "http://localhost:8080"

# Test đăng nhập với user vừa tạo
$loginData = @{
    username = "test"
    password = "test"
} | ConvertTo-Json

Write-Host "📡 Trying to login with test/test" -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/api/auth/login" -Method POST -ContentType "application/json" -Body $loginData -UseBasicParsing
    Write-Host "✅ Login successful!" -ForegroundColor Green
    Write-Host "Token: $($response.token)" -ForegroundColor Cyan
    
    # Lưu token để test API
    $token = $response.token
    
    # Test API customers với token
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
    }
    
    Write-Host "`n📡 Testing customers API with token" -ForegroundColor Yellow
    $customersResponse = Invoke-RestMethod -Uri "$baseUrl/api/customers" -Headers $headers -UseBasicParsing
    Write-Host "✅ Customers API works with token!" -ForegroundColor Green
    Write-Host "Response status: $($customersResponse.status)" -ForegroundColor Cyan
    Write-Host "Number of customers: $($customersResponse.data.Length)" -ForegroundColor Cyan
    
    # Test tạo customer mới
    Write-Host "`n📡 Testing create customer with token" -ForegroundColor Yellow
    $newCustomer = @{
        fullName = "Test Customer From API"
        email = "testapi@example.com"
        phone = "0123456789"
        address = "Test Address"
    } | ConvertTo-Json
    
    $createResponse = Invoke-RestMethod -Uri "$baseUrl/api/customers" -Method POST -Headers $headers -Body $newCustomer -UseBasicParsing
    Write-Host "✅ Customer created successfully!" -ForegroundColor Green
    Write-Host "New customer: $($createResponse.data.fullName)" -ForegroundColor Cyan
    
} catch {
    Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n🏁 Test completed!" -ForegroundColor Cyan
