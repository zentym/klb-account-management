#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Tạo customer data thông qua API Gateway
    
.DESCRIPTION
    Script tạo dữ liệu khách hàng mẫu thông qua API Gateway (port 8080) thay vì kết nối trực tiếp với customer service
    
.PARAMETER AdminPhone
    Số điện thoại của admin user (default: 0901234567)
    
.PARAMETER UserPhone
    Số điện thoại của regular user (default: 0987654321)
    
.PARAMETER SkipAuth
    Bỏ qua authentication (dùng cho testing)
    
.EXAMPLE
    .\setup-customer-data-via-gateway.ps1
    
.EXAMPLE
    .\setup-customer-data-via-gateway.ps1 -AdminPhone "0901111111" -UserPhone "0902222222"
#>

param(
    [string]$AdminPhone = "0901234567",
    [string]$UserPhone = "0987654321", 
    [switch]$SkipAuth
)

Write-Host "📊 Tạo customer data thông qua API Gateway..." -ForegroundColor Cyan
Write-Host ""

# Check if API Gateway is ready
Write-Host "⏳ Kiểm tra API Gateway..." -ForegroundColor Yellow
try {
    $gatewayHealth = Invoke-WebRequest -Uri "http://localhost:8080/" -UseBasicParsing -TimeoutSec 5
    if ($gatewayHealth.StatusCode -eq 401 -or $gatewayHealth.StatusCode -eq 200) {
        Write-Host "✅ API Gateway đã sẵn sàng!" -ForegroundColor Green
    }
} catch {
    if ($_.Exception.Response.StatusCode -eq 401) {
        Write-Host "✅ API Gateway đã sẵn sàng (requires auth)!" -ForegroundColor Green
    } else {
        Write-Host "❌ API Gateway không khả dụng: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "💡 Hãy đảm bảo docker-compose đã chạy: docker-compose up -d" -ForegroundColor Yellow
        exit 1
    }
}

$apiHeaders = @{ "Content-Type" = "application/json" }

# Get authentication token if not skipping auth
if (-not $SkipAuth) {
    Write-Host "🔐 Lấy authentication token..." -ForegroundColor Yellow
    try {
        $tokenData = "username=$AdminPhone&password=admin123&grant_type=password&client_id=klb-frontend"
        $tokenResponse = Invoke-RestMethod -Uri "http://localhost:8090/realms/Kienlongbank/protocol/openid-connect/token" -Method Post -Body $tokenData -ContentType "application/x-www-form-urlencoded"
        
        $apiHeaders["Authorization"] = "Bearer $($tokenResponse.access_token)"
        Write-Host "✅ Token đã lấy thành công" -ForegroundColor Green
    } catch {
        Write-Host "❌ Không thể lấy token: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "💡 Hãy đảm bảo Keycloak đang chạy và user $AdminPhone đã được tạo" -ForegroundColor Yellow
        exit 1
    }
} else {
    Write-Host "⚠️ Bỏ qua authentication (testing mode)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "👥 Tạo customer data..." -ForegroundColor Yellow

# Create admin customer
Write-Host "   📝 Tạo admin customer ($AdminPhone)..." -ForegroundColor White
$adminCustomer = @{
    firstName = "Nguyễn"
    lastName = "Văn Admin"
    email = "admin@kienlongbank.com"
    phoneNumber = $AdminPhone
    address = "123 Đường Nguyễn Huệ, Q1, TP.HCM"
    dateOfBirth = "1985-01-15"
    identityNumber = "123456789"
} | ConvertTo-Json

try {
    $adminCustomerResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/customers" -Method Post -Body $adminCustomer -Headers $apiHeaders
    Write-Host "   ✅ Admin customer đã tạo (ID: $($adminCustomerResponse.id))" -ForegroundColor Green
    $adminCustomerId = $adminCustomerResponse.id
} catch {
    if ($_.Exception.Response.StatusCode -eq 409) {
        Write-Host "   ℹ️ Admin customer đã tồn tại" -ForegroundColor Blue
        # Try to get existing customer ID
        try {
            $existingCustomers = Invoke-RestMethod -Uri "http://localhost:8080/api/customers" -Headers $apiHeaders
            $adminCustomerId = ($existingCustomers | Where-Object { $_.phoneNumber -eq $AdminPhone }).id
        } catch {
            $adminCustomerId = 1 # fallback
        }
    } else {
        Write-Host "   ❌ Lỗi tạo admin customer: $($_.Exception.Message)" -ForegroundColor Red
        $adminCustomerId = 1 # fallback
    }
}

# Create regular customer  
Write-Host "   📝 Tạo regular customer ($UserPhone)..." -ForegroundColor White
$regularCustomer = @{
    firstName = "Trần"
    lastName = "Thị User"
    email = "user@kienlongbank.com"
    phoneNumber = $UserPhone
    address = "456 Đường Lê Lợi, Q3, TP.HCM"
    dateOfBirth = "1990-05-20"
    identityNumber = "987654321"
} | ConvertTo-Json

try {
    $regularCustomerResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/customers" -Method Post -Body $regularCustomer -Headers $apiHeaders
    Write-Host "   ✅ Regular customer đã tạo (ID: $($regularCustomerResponse.id))" -ForegroundColor Green
    $regularCustomerId = $regularCustomerResponse.id
} catch {
    if ($_.Exception.Response.StatusCode -eq 409) {
        Write-Host "   ℹ️ Regular customer đã tồn tại" -ForegroundColor Blue
        # Try to get existing customer ID
        try {
            $existingCustomers = Invoke-RestMethod -Uri "http://localhost:8080/api/customers" -Headers $apiHeaders
            $regularCustomerId = ($existingCustomers | Where-Object { $_.phoneNumber -eq $UserPhone }).id
        } catch {
            $regularCustomerId = 2 # fallback
        }
    } else {
        Write-Host "   ❌ Lỗi tạo regular customer: $($_.Exception.Message)" -ForegroundColor Red
        $regularCustomerId = 2 # fallback
    }
}

Write-Host ""
Write-Host "🏦 Tạo bank accounts..." -ForegroundColor Yellow

# Create admin account
Write-Host "   💳 Tạo admin account..." -ForegroundColor White
$adminAccount = @{
    accountNumber = "001234567890"
    accountType = "SAVINGS"
    balance = 10000000
    customerId = $adminCustomerId
} | ConvertTo-Json

try {
    $adminAccountResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/accounts" -Method Post -Body $adminAccount -Headers $apiHeaders
    Write-Host "   ✅ Admin account đã tạo: 001234567890" -ForegroundColor Green
} catch {
    if ($_.Exception.Response.StatusCode -eq 409) {
        Write-Host "   ℹ️ Admin account đã tồn tại" -ForegroundColor Blue
    } else {
        Write-Host "   ❌ Lỗi tạo admin account: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Create regular account
Write-Host "   💳 Tạo regular account..." -ForegroundColor White
$regularAccount = @{
    accountNumber = "009876543210"
    accountType = "CHECKING"
    balance = 5000000
    customerId = $regularCustomerId
} | ConvertTo-Json

try {
    $regularAccountResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/accounts" -Method Post -Body $regularAccount -Headers $apiHeaders
    Write-Host "   ✅ Regular account đã tạo: 009876543210" -ForegroundColor Green
} catch {
    if ($_.Exception.Response.StatusCode -eq 409) {
        Write-Host "   ℹ️ Regular account đã tồn tại" -ForegroundColor Blue
    } else {
        Write-Host "   ❌ Lỗi tạo regular account: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "🔍 Kiểm tra dữ liệu đã tạo..." -ForegroundColor Yellow

# Verify customers
try {
    $customers = Invoke-RestMethod -Uri "http://localhost:8080/api/customers" -Headers $apiHeaders
    Write-Host "   ✅ Tìm thấy $($customers.Count) customers:" -ForegroundColor Green
    $customers | ForEach-Object { 
        Write-Host "     - $($_.firstName) $($_.lastName) (Phone: $($_.phoneNumber))" -ForegroundColor White
    }
} catch {
    Write-Host "   ⚠️ Không thể kiểm tra customers: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Verify accounts
try {
    $accounts = Invoke-RestMethod -Uri "http://localhost:8080/api/accounts" -Headers $apiHeaders
    Write-Host "   ✅ Tìm thấy $($accounts.Count) accounts:" -ForegroundColor Green
    $accounts | ForEach-Object { 
        Write-Host "     - Account: $($_.accountNumber), Balance: $($_.balance) VND" -ForegroundColor White
    }
} catch {
    Write-Host "   ⚠️ Không thể kiểm tra accounts: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🎉 Setup customer data hoàn tất!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Dữ liệu đã tạo:" -ForegroundColor Cyan
Write-Host "   👤 Admin: Nguyễn Văn Admin (SĐT: $AdminPhone)" -ForegroundColor White
Write-Host "   👤 User: Trần Thị User (SĐT: $UserPhone)" -ForegroundColor White
Write-Host "   💳 Admin Account: 001234567890 (Số dư: 10,000,000 VND)" -ForegroundColor White
Write-Host "   💳 User Account: 009876543210 (Số dư: 5,000,000 VND)" -ForegroundColor White
Write-Host ""
Write-Host "🚀 Bây giờ bạn có thể test APIs:" -ForegroundColor Green
Write-Host "   - Customers API: http://localhost:8080/api/customers" -ForegroundColor White
Write-Host "   - Accounts API: http://localhost:8080/api/accounts" -ForegroundColor White
Write-Host "   - All APIs routed through API Gateway on port 8080" -ForegroundColor White
