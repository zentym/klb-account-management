#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Thiết lập dữ liệu khách hàng mẫu
    
.DESCRIPTION
    Script tạo customer data và accounts mẫu cho hệ thống banking
    
.PARAMETER AdminPhone
    Số điện thoại của admin user
    
.PARAMETER UserPhone
    Số điện thoại của regular user
    
.PARAMETER AdminPassword
    Mật khẩu của admin user
    
.PARAMETER UserPassword
    Mật khẩu của regular user

.PARAMETER SkipAuth
    Bỏ qua xác thực và sử dụng admin token trực tiếp
    
.EXAMPLE
    .\setup-customer-data.ps1
    
.EXAMPLE
    .\setup-customer-data.ps1 -AdminPhone "0901111111" -UserPhone "0902222222"
    
.EXAMPLE
    .\setup-customer-data.ps1 -SkipAuth
#>

param(
    [string]$AdminPhone = "0901234567",
    [string]$UserPhone = "0987654321",
    [string]$AdminPassword = "admin123",
    [string]$UserPassword = "password123",
    [switch]$SkipAuth
)

Write-Host "👥 Thiết lập dữ liệu khách hàng mẫu..." -ForegroundColor Cyan
Write-Host ""

# Wait for services to be ready
Write-Host "⏳ Chờ services sẵn sàng..." -ForegroundColor Yellow
$servicesReady = $false
$maxRetries = 30
$retryCount = 0

while (-not $servicesReady -and $retryCount -lt $maxRetries) {
    try {
        # Check main service
        $mainResponse = Invoke-WebRequest -Uri "http://localhost:8080/actuator/health" -UseBasicParsing -TimeoutSec 3
        # Check customer service  
        $customerResponse = Invoke-WebRequest -Uri "http://localhost:8082/actuator/health" -UseBasicParsing -TimeoutSec 3
        
        if ($mainResponse.StatusCode -eq 200 -and $customerResponse.StatusCode -eq 200) {
            $servicesReady = $true
            Write-Host "✅ Tất cả services đã sẵn sàng!" -ForegroundColor Green
        }
    } catch {
        $retryCount++
        Write-Host "⏳ Đang chờ services... ($retryCount/$maxRetries)" -ForegroundColor Yellow
        Start-Sleep 3
    }
}

if (-not $servicesReady) {
    Write-Host "❌ Services chưa sẵn sàng. Hãy đảm bảo docker-compose đã chạy." -ForegroundColor Red
    Write-Host "💡 Chạy: cd kienlongbank-project && docker-compose up -d" -ForegroundColor Yellow
    exit 1
}

# Get authentication token
$apiHeaders = @{"Content-Type" = "application/json"}

if (-not $SkipAuth) {
    Write-Host "🔐 Lấy token xác thực..." -ForegroundColor Yellow
    try {
        $tokenData = @{
            username = $AdminPhone
            password = $AdminPassword
            grant_type = "password"
            client_id = "klb-frontend"
        }
        
        $tokenBody = ($tokenData.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join "&"
        $tokenResponse = Invoke-RestMethod -Uri "http://localhost:8090/realms/Kienlongbank/protocol/openid-connect/token" -Method Post -Body $tokenBody -ContentType "application/x-www-form-urlencoded"
        
        $accessToken = $tokenResponse.access_token
        $apiHeaders["Authorization"] = "Bearer $accessToken"
        
        Write-Host "✅ Đã lấy token xác thực" -ForegroundColor Green
    } catch {
        Write-Host "⚠️ Không thể lấy token xác thực: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host "🔄 Sử dụng chế độ không xác thực..." -ForegroundColor Yellow
        # Continue without auth for testing
    }
} else {
    Write-Host "ℹ️ Chạy ở chế độ không xác thực" -ForegroundColor Blue
}

# Create customer data
Write-Host "👥 Tạo thông tin khách hàng..." -ForegroundColor Yellow

# Admin customer
$adminCustomer = @{
    firstName = "Nguyễn"
    lastName = "Văn Admin"
    email = "admin@kienlongbank.com"
    phoneNumber = $AdminPhone
    address = "123 Đường Nguyễn Huệ, Quận 1, TP.HCM"
    dateOfBirth = "1985-01-15"
    identityNumber = "123456789012"
    customerType = "PREMIUM"
    status = "ACTIVE"
} | ConvertTo-Json

Write-Host "📝 Tạo khách hàng Admin ($AdminPhone)..." -ForegroundColor Yellow
try {
    $adminCustomerResponse = Invoke-RestMethod -Uri "http://localhost:8082/api/customers" -Method Post -Body $adminCustomer -Headers $apiHeaders
    Write-Host "✅ Đã tạo khách hàng Admin (ID: $($adminCustomerResponse.id))" -ForegroundColor Green
    $adminCustomerId = $adminCustomerResponse.id
} catch {
    if ($_.Exception.Response.StatusCode -eq 409) {
        Write-Host "ℹ️ Khách hàng Admin đã tồn tại, lấy thông tin..." -ForegroundColor Blue
        try {
            $existingCustomers = Invoke-RestMethod -Uri "http://localhost:8082/api/customers?phoneNumber=$AdminPhone" -Headers $apiHeaders
            if ($existingCustomers -and $existingCustomers.Count -gt 0) {
                $adminCustomerId = $existingCustomers[0].id
                Write-Host "✅ Tìm thấy khách hàng Admin (ID: $adminCustomerId)" -ForegroundColor Green
            } else {
                $adminCustomerId = 1  # fallback ID
            }
        } catch {
            $adminCustomerId = 1  # fallback ID
        }
    } else {
        Write-Host "⚠️ Lỗi tạo khách hàng Admin: $($_.Exception.Message)" -ForegroundColor Yellow
        $adminCustomerId = 1  # fallback ID
    }
}

# Regular customer
$regularCustomer = @{
    firstName = "Trần"
    lastName = "Thị User"
    email = "user@kienlongbank.com" 
    phoneNumber = $UserPhone
    address = "456 Đường Lê Lợi, Quận 3, TP.HCM"
    dateOfBirth = "1990-05-20"
    identityNumber = "987654321098"
    customerType = "STANDARD"
    status = "ACTIVE"
} | ConvertTo-Json

Write-Host "📝 Tạo khách hàng User ($UserPhone)..." -ForegroundColor Yellow
try {
    $regularCustomerResponse = Invoke-RestMethod -Uri "http://localhost:8082/api/customers" -Method Post -Body $regularCustomer -Headers $apiHeaders
    Write-Host "✅ Đã tạo khách hàng User (ID: $($regularCustomerResponse.id))" -ForegroundColor Green
    $regularCustomerId = $regularCustomerResponse.id
} catch {
    if ($_.Exception.Response.StatusCode -eq 409) {
        Write-Host "ℹ️ Khách hàng User đã tồn tại, lấy thông tin..." -ForegroundColor Blue
        try {
            $existingCustomers = Invoke-RestMethod -Uri "http://localhost:8082/api/customers?phoneNumber=$UserPhone" -Headers $apiHeaders
            if ($existingCustomers -and $existingCustomers.Count -gt 0) {
                $regularCustomerId = $existingCustomers[0].id
                Write-Host "✅ Tìm thấy khách hàng User (ID: $regularCustomerId)" -ForegroundColor Green
            } else {
                $regularCustomerId = 2  # fallback ID
            }
        } catch {
            $regularCustomerId = 2  # fallback ID
        }
    } else {
        Write-Host "⚠️ Lỗi tạo khách hàng User: $($_.Exception.Message)" -ForegroundColor Yellow
        $regularCustomerId = 2  # fallback ID
    }
}

# Create sample accounts
Write-Host "🏦 Tạo tài khoản ngân hàng mẫu..." -ForegroundColor Yellow

# Admin account
$adminAccount = @{
    accountNumber = "001234567890"
    accountType = "SAVINGS"
    balance = 10000000.0
    customerId = $adminCustomerId
    status = "ACTIVE"
    currency = "VND"
} | ConvertTo-Json

Write-Host "💳 Tạo tài khoản Admin (001234567890)..." -ForegroundColor Yellow
try {
    $adminAccountResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/accounts" -Method Post -Body $adminAccount -Headers $apiHeaders
    Write-Host "✅ Đã tạo tài khoản Admin: 001234567890 (Số dư: 10,000,000 VND)" -ForegroundColor Green
} catch {
    if ($_.Exception.Response.StatusCode -eq 409) {
        Write-Host "ℹ️ Tài khoản Admin đã tồn tại" -ForegroundColor Blue
    } else {
        Write-Host "⚠️ Lỗi tạo tài khoản Admin: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

# Regular user account
$regularAccount = @{
    accountNumber = "009876543210"
    accountType = "CHECKING"
    balance = 5000000.0
    customerId = $regularCustomerId
    status = "ACTIVE"
    currency = "VND"
} | ConvertTo-Json

Write-Host "💳 Tạo tài khoản User (009876543210)..." -ForegroundColor Yellow
try {
    $regularAccountResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/accounts" -Method Post -Body $regularAccount -Headers $apiHeaders
    Write-Host "✅ Đã tạo tài khoản User: 009876543210 (Số dư: 5,000,000 VND)" -ForegroundColor Green
} catch {
    if ($_.Exception.Response.StatusCode -eq 409) {
        Write-Host "ℹ️ Tài khoản User đã tồn tại" -ForegroundColor Blue
    } else {
        Write-Host "⚠️ Lỗi tạo tài khoản User: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

# Create additional sample accounts
Write-Host "🏦 Tạo thêm tài khoản mẫu..." -ForegroundColor Yellow

# Admin checking account
$adminCheckingAccount = @{
    accountNumber = "001234567891"
    accountType = "CHECKING"
    balance = 2000000.0
    customerId = $adminCustomerId
    status = "ACTIVE"
    currency = "VND"
} | ConvertTo-Json

try {
    Invoke-RestMethod -Uri "http://localhost:8080/api/accounts" -Method Post -Body $adminCheckingAccount -Headers $apiHeaders
    Write-Host "✅ Đã tạo tài khoản Checking cho Admin: 001234567891" -ForegroundColor Green
} catch {
    if ($_.Exception.Response.StatusCode -eq 409) {
        Write-Host "ℹ️ Tài khoản Checking Admin đã tồn tại" -ForegroundColor Blue
    }
}

# User savings account
$userSavingsAccount = @{
    accountNumber = "009876543211"
    accountType = "SAVINGS"
    balance = 1500000.0
    customerId = $regularCustomerId
    status = "ACTIVE"
    currency = "VND"
} | ConvertTo-Json

try {
    Invoke-RestMethod -Uri "http://localhost:8080/api/accounts" -Method Post -Body $userSavingsAccount -Headers $apiHeaders
    Write-Host "✅ Đã tạo tài khoản Savings cho User: 009876543211" -ForegroundColor Green
} catch {
    if ($_.Exception.Response.StatusCode -eq 409) {
        Write-Host "ℹ️ Tài khoản Savings User đã tồn tại" -ForegroundColor Blue
    }
}

Write-Host ""
Write-Host "🎉 Thiết lập dữ liệu khách hàng hoàn tất!" -ForegroundColor Green
Write-Host ""
Write-Host "👥 Thông tin khách hàng đã tạo:" -ForegroundColor Cyan
Write-Host "   Admin: Nguyễn Văn Admin" -ForegroundColor White
Write-Host "     - SĐT: $AdminPhone" -ForegroundColor White
Write-Host "     - Email: admin@kienlongbank.com" -ForegroundColor White
Write-Host "     - CMND: 123456789012" -ForegroundColor White
Write-Host "   User: Trần Thị User" -ForegroundColor White
Write-Host "     - SĐT: $UserPhone" -ForegroundColor White
Write-Host "     - Email: user@kienlongbank.com" -ForegroundColor White
Write-Host "     - CMND: 987654321098" -ForegroundColor White
Write-Host ""
Write-Host "🏦 Tài khoản đã tạo:" -ForegroundColor Cyan
Write-Host "   Admin Savings: 001234567890 (10,000,000 VND)" -ForegroundColor White
Write-Host "   Admin Checking: 001234567891 (2,000,000 VND)" -ForegroundColor White
Write-Host "   User Checking: 009876543210 (5,000,000 VND)" -ForegroundColor White
Write-Host "   User Savings: 009876543211 (1,500,000 VND)" -ForegroundColor White
Write-Host ""
Write-Host "🔧 Test commands:" -ForegroundColor Yellow
Write-Host "   .\quick-api-test.ps1" -ForegroundColor White
Write-Host "   .\test-api-tool.ps1 -Service all" -ForegroundColor White
Write-Host ""
