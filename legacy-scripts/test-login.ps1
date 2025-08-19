# Test đăng nhập để lấy JWT token
Write-Host "🔐 Testing Login API" -ForegroundColor Cyan
Write-Host "===========================" -ForegroundColor Cyan

$baseUrl = "http://localhost:8080"

# Thử đăng nhập với admin user đầu tiên
$loginData = @{
    username = "admin1"
    password = "admin123"
} | ConvertTo-Json

Write-Host "📡 Trying to login with admin1/admin123" -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/api/auth/login" -Method POST -ContentType "application/json" -Body $loginData -UseBasicParsing
    Write-Host "✅ Login successful!" -ForegroundColor Green
    Write-Host "Token: $($response.token)" -ForegroundColor Cyan
    Write-Host "Message: $($response.message)" -ForegroundColor Cyan
    
    # Test API với token này
    $headers = @{
        "Authorization" = "Bearer $($response.token)"
        "Content-Type"  = "application/json"
    }
    
    Write-Host "`n📡 Testing customers API with token" -ForegroundColor Yellow
    $customersResponse = Invoke-RestMethod -Uri "$baseUrl/api/customers" -Headers $headers -UseBasicParsing
    Write-Host "✅ Customers API works with token!" -ForegroundColor Green
    Write-Host "Number of customers: $($customersResponse.data.Length)" -ForegroundColor Cyan
    
}
catch {
    Write-Host "❌ Login failed: $($_.Exception.Message)" -ForegroundColor Red
    
    # Thử với các admin user khác
    $otherAdmins = @(
        @{username = "admin"; password = "admin123" },
        @{username = "admin2"; password = "admin123" },
        @{username = "ducadmin"; password = "123456" }
    )
    
    foreach ($admin in $otherAdmins) {
        Write-Host "`n📡 Trying to login with $($admin.username)/$($admin.password)" -ForegroundColor Yellow
        try {
            $adminData = $admin | ConvertTo-Json
            $response = Invoke-RestMethod -Uri "$baseUrl/api/auth/login" -Method POST -ContentType "application/json" -Body $adminData -UseBasicParsing
            Write-Host "✅ Login successful with $($admin.username)!" -ForegroundColor Green
            Write-Host "Token: $($response.token)" -ForegroundColor Cyan
            break
        }
        catch {
            Write-Host "❌ Failed with $($admin.username): $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

Write-Host "`n🏁 Test completed!" -ForegroundColor Cyan
