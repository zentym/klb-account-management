#!/usr/bin/env pwsh
# Script kiểm tra quyền tạo account của user

Write-Host "🏦 Kiểm tra quyền tạo Account của User" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan

$baseUrl = "http://localhost:8080"
$keycloakUrl = "http://localhost:8090"

# Step 1: Đăng nhập và lấy token
Write-Host "`n🔐 Step 1: Đăng nhập với testuser..." -ForegroundColor Yellow

$loginData = @{
    "username" = "testuser"
    "password" = "password123" 
    "grant_type" = "password"
    "client_id" = "klb-frontend"
}

try {
    $tokenResponse = Invoke-RestMethod -Uri "$keycloakUrl/realms/Kienlongbank/protocol/openid-connect/token" -Method Post -Body $loginData -ContentType "application/x-www-form-urlencoded"
    $accessToken = $tokenResponse.access_token
    Write-Host "✅ Đăng nhập thành công!" -ForegroundColor Green
    Write-Host "📋 Token có độ dài: $($accessToken.Length) ký tự" -ForegroundColor Gray
} catch {
    Write-Host "❌ Đăng nhập thất bại: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

$authHeaders = @{
    "Authorization" = "Bearer $accessToken"
    "Content-Type" = "application/json"
}

# Step 2: Kiểm tra health endpoint
Write-Host "`n💓 Step 2: Kiểm tra kết nối API..." -ForegroundColor Yellow
try {
    $healthResponse = Invoke-RestMethod -Uri "$baseUrl/api/health" -Method Get
    Write-Host "✅ API Health check: $healthResponse" -ForegroundColor Green
} catch {
    Write-Host "❌ API không khả dụng: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Step 3: Thử lấy danh sách customers (cần authentication)
Write-Host "`n👥 Step 3: Kiểm tra quyền truy cập Customer API..." -ForegroundColor Yellow
try {
    $customersResponse = Invoke-RestMethod -Uri "http://localhost:8082/api/customers" -Method Get -Headers $authHeaders
    Write-Host "✅ Truy cập Customer API thành công!" -ForegroundColor Green
    $customerCount = $customersResponse.data.Count
    Write-Host "📊 Tìm thấy $customerCount customers" -ForegroundColor Gray
    
    if ($customerCount -gt 0) {
        $testCustomerId = $customersResponse.data[0].id
        Write-Host "🎯 Sẽ test với customer ID: $testCustomerId" -ForegroundColor Blue
    } else {
        Write-Host "⚠️ Không có customer nào để test. Tạo customer test..." -ForegroundColor Yellow
        
        # Tạo customer test
        $newCustomer = @{
            fullName = "Test Customer"
            email = "test.customer@kienlongbank.com"
            phone = "0123456789"
            address = "Test Address"
        } | ConvertTo-Json
        
        try {
            $createCustomerResponse = Invoke-RestMethod -Uri "http://localhost:8082/api/customers" -Method Post -Headers $authHeaders -Body $newCustomer
            $testCustomerId = $createCustomerResponse.data.id
            Write-Host "✅ Tạo customer test thành công! ID: $testCustomerId" -ForegroundColor Green
        } catch {
            Write-Host "❌ Không thể tạo customer test: $($_.Exception.Message)" -ForegroundColor Red
            exit 1
        }
    }
} catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    Write-Host "❌ Không thể truy cập Customer API (Status: $statusCode): $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Step 4: Kiểm tra quyền tạo account
Write-Host "`n💳 Step 4: Kiểm tra quyền tạo Account..." -ForegroundColor Yellow

$newAccount = @{
    accountType = "SAVINGS"
    balance = 1000.0
} | ConvertTo-Json

try {
    $createAccountResponse = Invoke-RestMethod -Uri "$baseUrl/api/customers/$testCustomerId/accounts" -Method Post -Headers $authHeaders -Body $newAccount
    Write-Host "✅ TẠO ACCOUNT THÀNH CÔNG!" -ForegroundColor Green
    Write-Host "📋 Account details:" -ForegroundColor Blue
    Write-Host "   - Account ID: $($createAccountResponse.id)" -ForegroundColor White
    Write-Host "   - Account Number: $($createAccountResponse.accountNumber)" -ForegroundColor White
    Write-Host "   - Account Type: $($createAccountResponse.accountType)" -ForegroundColor White
    Write-Host "   - Balance: $($createAccountResponse.balance)" -ForegroundColor White
    Write-Host "   - Customer ID: $($createAccountResponse.customerId)" -ForegroundColor White
} catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    Write-Host "❌ KHÔNG THỂ TẠO ACCOUNT (Status: $statusCode)" -ForegroundColor Red
    
    if ($statusCode -eq 401) {
        Write-Host "🔐 Lỗi 401: Token không hợp lệ hoặc hết hạn" -ForegroundColor Yellow
    } elseif ($statusCode -eq 403) {
        Write-Host "🚫 Lỗi 403: User không có quyền tạo account" -ForegroundColor Yellow
    } elseif ($statusCode -eq 404) {
        Write-Host "❓ Lỗi 404: Customer không tồn tại (ID: $testCustomerId)" -ForegroundColor Yellow
    } else {
        Write-Host "⚠️ Lỗi khác: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    
    # Đọc thêm thông tin lỗi
    try {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $errorContent = $reader.ReadToEnd()
        Write-Host "📝 Chi tiết lỗi: $errorContent" -ForegroundColor Gray
    } catch {
        Write-Host "📝 Không đọc được chi tiết lỗi" -ForegroundColor Gray
    }
}

# Step 5: Kiểm tra quyền xem accounts (nếu tạo thành công)
Write-Host "`n📋 Step 5: Kiểm tra quyền xem danh sách accounts..." -ForegroundColor Yellow
try {
    $accountsResponse = Invoke-RestMethod -Uri "$baseUrl/api/customers/$testCustomerId/accounts" -Method Get -Headers $authHeaders
    $accountCount = $accountsResponse.Count
    Write-Host "✅ Xem danh sách accounts thành công!" -ForegroundColor Green
    Write-Host "📊 Customer có $accountCount accounts" -ForegroundColor Gray
} catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    Write-Host "❌ Không thể xem accounts (Status: $statusCode): $($_.Exception.Message)" -ForegroundColor Red
}

# Step 6: Kiểm tra quyền admin (để so sánh)
Write-Host "`n👑 Step 6: Kiểm tra quyền Admin (để so sánh)..." -ForegroundColor Yellow
try {
    $adminResponse = Invoke-RestMethod -Uri "$baseUrl/api/admin/hello" -Method Get -Headers $authHeaders
    Write-Host "✅ User có quyền Admin!" -ForegroundColor Green
    Write-Host "📋 Admin response: $adminResponse" -ForegroundColor Gray
} catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    if ($statusCode -eq 401 -or $statusCode -eq 403) {
        Write-Host "❌ User KHÔNG có quyền Admin (Status: $statusCode)" -ForegroundColor Red
        Write-Host "💡 Đây là bình thường cho user thường" -ForegroundColor Blue
    } else {
        Write-Host "❌ Lỗi kiểm tra quyền admin: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n📊 TỔNG KẾT:" -ForegroundColor Cyan
Write-Host "============" -ForegroundColor Cyan
Write-Host "🔐 User đã đăng nhập: testuser" -ForegroundColor White
Write-Host "💳 Quyền tạo account: " -NoNewline -ForegroundColor White

# Kiểm tra lại xem có account mới không
try {
    $finalAccountsResponse = Invoke-RestMethod -Uri "$baseUrl/api/customers/$testCustomerId/accounts" -Method Get -Headers $authHeaders
    $finalAccountCount = $finalAccountsResponse.Count
    if ($finalAccountCount -gt 0) {
        Write-Host "✅ CÓ QUYỀN" -ForegroundColor Green
        Write-Host "📋 User có thể tạo và quản lý accounts cho customers" -ForegroundColor Green
    } else {
        Write-Host "❌ KHÔNG CÓ QUYỀN" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ KHÔNG CÓ QUYỀN" -ForegroundColor Red
}

Write-Host "`n🏁 Kiểm tra hoàn tất!" -ForegroundColor Cyan
