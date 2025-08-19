# Test User Loan List API
# Script để test API xem danh sách khoản vay của user

param(
    [string]$BaseUrl = "http://localhost:8082",
    [string]$CustomerToken = "",
    [string]$AdminToken = "",
    [int]$CustomerId = 123
)

function Write-TestHeader {
    param([string]$Title)
    Write-Host "`n" + "="*50 -ForegroundColor Cyan
    Write-Host $Title -ForegroundColor Yellow
    Write-Host "="*50 -ForegroundColor Cyan
}

function Test-GetCustomerLoans {
    param(
        [string]$Token,
        [int]$CustomerId,
        [string]$Role
    )
    
    Write-TestHeader "Test: $Role xem danh sách khoản vay của customer $CustomerId"
    
    try {
        $headers = @{
            "Authorization" = "Bearer $Token"
            "Content-Type"  = "application/json"
        }
        
        $response = Invoke-RestMethod -Uri "$BaseUrl/api/loans/customer/$CustomerId" `
            -Method GET `
            -Headers $headers
        
        Write-Host "✅ SUCCESS: Lấy danh sách khoản vay thành công" -ForegroundColor Green
        Write-Host "Số lượng khoản vay: $($response.Length)" -ForegroundColor Green
        
        if ($response.Length -gt 0) {
            Write-Host "`nChi tiết khoản vay:" -ForegroundColor White
            foreach ($loan in $response) {
                Write-Host "  - ID: $($loan.id), Số tiền: $($loan.amount), Trạng thái: $($loan.status)" -ForegroundColor White
                Write-Host "    Ngày đăng ký: $($loan.applicationDate)" -ForegroundColor Gray
            }
        }
        else {
            Write-Host "Khách hàng chưa có khoản vay nào." -ForegroundColor Gray
        }
        
        return $true
    }
    catch {
        Write-Host "❌ ERROR: $($_.Exception.Message)" -ForegroundColor Red
        if ($_.Exception.Response) {
            $errorResponse = $_.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($errorResponse)
            $errorBody = $reader.ReadToEnd()
            Write-Host "Response body: $errorBody" -ForegroundColor Red
        }
        return $false
    }
}

function Test-SecurityRestriction {
    param(
        [string]$CustomerToken,
        [int]$TargetCustomerId
    )
    
    Write-TestHeader "Test: Customer cố gắng xem khoản vay của customer khác"
    
    try {
        $headers = @{
            "Authorization" = "Bearer $CustomerToken"
            "Content-Type"  = "application/json"
        }
        
        $response = Invoke-RestMethod -Uri "$BaseUrl/api/loans/customer/$TargetCustomerId" `
            -Method GET `
            -Headers $headers
        
        Write-Host "❌ SECURITY ISSUE: Customer có thể xem khoản vay của người khác!" -ForegroundColor Red
        return $false
    }
    catch {
        if ($_.Exception.Response.StatusCode -eq 403) {
            Write-Host "✅ SUCCESS: Bảo mật hoạt động đúng - Access denied" -ForegroundColor Green
            return $true
        }
        else {
            Write-Host "❌ UNEXPECTED ERROR: $($_.Exception.Message)" -ForegroundColor Red
            return $false
        }
    }
}

function Test-HealthCheck {
    Write-TestHeader "Test: Health Check"
    
    try {
        $response = Invoke-RestMethod -Uri "$BaseUrl/api/loans/public/health" -Method GET
        Write-Host "✅ Service is UP" -ForegroundColor Green
        Write-Host "Service: $($response.service)" -ForegroundColor White
        Write-Host "Status: $($response.status)" -ForegroundColor White
        Write-Host "Timestamp: $($response.timestamp)" -ForegroundColor White
        return $true
    }
    catch {
        Write-Host "❌ Service health check failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Main test execution
Write-Host "🧪 USER LOAN LIST API TEST SUITE" -ForegroundColor Magenta
Write-Host "Base URL: $BaseUrl" -ForegroundColor White

# Health check trước
$healthOk = Test-HealthCheck

if (-not $healthOk) {
    Write-Host "`n❌ Service không khả dụng. Dừng test." -ForegroundColor Red
    exit 1
}

$results = @()

# Test với Customer token (nếu có)
if ($CustomerToken) {
    $results += Test-GetCustomerLoans -Token $CustomerToken -CustomerId $CustomerId -Role "Customer"
    
    # Test bảo mật - customer cố xem khoản vay của người khác
    $otherCustomerId = $CustomerId + 1
    $results += Test-SecurityRestriction -CustomerToken $CustomerToken -TargetCustomerId $otherCustomerId
}
else {
    Write-Host "`n⚠️  Không có Customer token để test" -ForegroundColor Yellow
}

# Test với Admin token (nếu có)
if ($AdminToken) {
    $results += Test-GetCustomerLoans -Token $AdminToken -CustomerId $CustomerId -Role "Admin"
    
    # Admin test với customer khác
    $otherCustomerId = $CustomerId + 1
    $results += Test-GetCustomerLoans -Token $AdminToken -CustomerId $otherCustomerId -Role "Admin"
}
else {
    Write-Host "`n⚠️  Không có Admin token để test" -ForegroundColor Yellow
}

# Test với token không hợp lệ
Write-TestHeader "Test: Token không hợp lệ"
try {
    $headers = @{
        "Authorization" = "Bearer invalid_token"
        "Content-Type"  = "application/json"
    }
    
    $response = Invoke-RestMethod -Uri "$BaseUrl/api/loans/customer/$CustomerId" `
        -Method GET `
        -Headers $headers
    
    Write-Host "❌ SECURITY ISSUE: API chấp nhận token không hợp lệ!" -ForegroundColor Red
    $results += $false
}
catch {
    if ($_.Exception.Response.StatusCode -eq 401) {
        Write-Host "✅ SUCCESS: Token validation hoạt động đúng" -ForegroundColor Green
        $results += $true
    }
    else {
        Write-Host "❌ UNEXPECTED ERROR: $($_.Exception.Message)" -ForegroundColor Red
        $results += $false
    }
}

# Tổng kết
Write-TestHeader "KẾT QUẢ TỔNG QUAN"
$passed = ($results | Where-Object { $_ -eq $true }).Count
$total = $results.Count

if ($total -gt 0) {
    Write-Host "Tests passed: $passed/$total" -ForegroundColor $(if ($passed -eq $total) { "Green" } else { "Yellow" })
    
    if ($passed -eq $total) {
        Write-Host "🎉 TẤT CẢ TESTS ĐỀU PASS!" -ForegroundColor Green
    }
    else {
        Write-Host "⚠️  MỘT SỐ TESTS BỊ FAIL" -ForegroundColor Yellow
    }
}
else {
    Write-Host "❌ KHÔNG CÓ TESTS NÀO ĐƯỢC CHẠY" -ForegroundColor Red
}

Write-Host "`n📝 Để chạy test với tokens thực tế:" -ForegroundColor Cyan
Write-Host ".\test-user-loan-list.ps1 -CustomerToken `"<customer_jwt>`" -AdminToken `"<admin_jwt>`" -CustomerId 123" -ForegroundColor White
