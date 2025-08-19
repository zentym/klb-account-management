#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Debug và test API Gateway connections
    
.DESCRIPTION
    Script để kiểm tra và debug connection tới các APIs thông qua API Gateway
#>

Write-Host "🔍 Debug API Gateway & Services..." -ForegroundColor Cyan
Write-Host ""

# Check Keycloak
Write-Host "1. 🔐 Kiểm tra Keycloak..." -ForegroundColor Yellow
try {
    $keycloakHealth = Invoke-WebRequest -Uri "http://localhost:8090/realms/master/.well-known/openid-configuration" -UseBasicParsing
    Write-Host "   ✅ Keycloak OK (Status: $($keycloakHealth.StatusCode))" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Keycloak Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Check API Gateway
Write-Host "2. 🌐 Kiểm tra API Gateway..." -ForegroundColor Yellow
try {
    $gatewayResponse = Invoke-WebRequest -Uri "http://localhost:8080/" -UseBasicParsing -TimeoutSec 3
    Write-Host "   ✅ API Gateway responding (Status: $($gatewayResponse.StatusCode))" -ForegroundColor Green
} catch {
    if ($_.Exception.Response.StatusCode -eq 401) {
        Write-Host "   ✅ API Gateway OK - requires authentication" -ForegroundColor Green
    } else {
        Write-Host "   ❌ API Gateway Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Get token
Write-Host "3. 🎫 Lấy authentication token..." -ForegroundColor Yellow
try {
    $tokenData = "username=0901234567&password=admin123&grant_type=password&client_id=klb-frontend"
    $tokenResponse = Invoke-RestMethod -Uri "http://localhost:8090/realms/Kienlongbank/protocol/openid-connect/token" -Method Post -Body $tokenData -ContentType "application/x-www-form-urlencoded"
    
    Write-Host "   ✅ Token obtained successfully" -ForegroundColor Green
    Write-Host "   Token type: $($tokenResponse.token_type)" -ForegroundColor Gray
    Write-Host "   Expires in: $($tokenResponse.expires_in) seconds" -ForegroundColor Gray
    Write-Host "   Scope: $($tokenResponse.scope)" -ForegroundColor Gray
    
    $headers = @{
        "Authorization" = "$($tokenResponse.token_type) $($tokenResponse.access_token)"
        "Content-Type" = "application/json"
    }
    
} catch {
    Write-Host "   ❌ Token Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "4. 🧪 Test các API endpoints..." -ForegroundColor Yellow

# Test customers API
Write-Host "   📝 Test /api/customers (GET)..." -ForegroundColor White
try {
    $customersResponse = Invoke-WebRequest -Uri "http://localhost:8080/api/customers" -Method Get -Headers $headers -UseBasicParsing
    Write-Host "      ✅ Success (Status: $($customersResponse.StatusCode))" -ForegroundColor Green
    
    $customers = $customersResponse.Content | ConvertFrom-Json
    if ($customers -and $customers.Count -gt 0) {
        Write-Host "      Found $($customers.Count) customers:" -ForegroundColor White
        $customers | ForEach-Object { 
            Write-Host "        - $($_.firstName) $($_.lastName) ($($_.phoneNumber))" -ForegroundColor Gray
        }
    } else {
        Write-Host "      No customers found (empty response)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "      ❌ Error: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        Write-Host "      Status: $($_.Exception.Response.StatusCode)" -ForegroundColor Red
        Write-Host "      Response: $($_.Exception.Response)" -ForegroundColor Red
    }
}

# Test accounts API
Write-Host "   💳 Test /api/accounts (GET)..." -ForegroundColor White
try {
    $accountsResponse = Invoke-WebRequest -Uri "http://localhost:8080/api/accounts" -Method Get -Headers $headers -UseBasicParsing
    Write-Host "      ✅ Success (Status: $($accountsResponse.StatusCode))" -ForegroundColor Green
    
    $accounts = $accountsResponse.Content | ConvertFrom-Json
    if ($accounts -and $accounts.Count -gt 0) {
        Write-Host "      Found $($accounts.Count) accounts:" -ForegroundColor White
        $accounts | ForEach-Object { 
            Write-Host "        - Account: $($_.accountNumber), Balance: $($_.balance)" -ForegroundColor Gray
        }
    } else {
        Write-Host "      No accounts found (empty response)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "      ❌ Error: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        Write-Host "      Status: $($_.Exception.Response.StatusCode)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "5. 🔍 Kiểm tra services trong Docker..." -ForegroundColor Yellow
$runningServices = docker ps --format "table {{.Names}}\t{{.Status}}" | Select-String "klb-"
$runningServices | ForEach-Object {
    Write-Host "   $($_)" -ForegroundColor White
}

Write-Host ""
Write-Host "6. 📋 Kết luận..." -ForegroundColor Cyan
Write-Host "   - Nếu APIs trả về 401: Có thể API Gateway chưa được cấu hình đúng cho JWT validation" -ForegroundColor White
Write-Host "   - Nếu APIs trả về empty data: Services đang hoạt động nhưng chưa có dữ liệu" -ForegroundColor White  
Write-Host "   - Nếu APIs hoạt động: Có thể tạo customer data thủ công qua POST requests" -ForegroundColor White
