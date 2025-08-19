# Test Admin Loan Status Update API
# PowerShell script để test API cập nhật trạng thái khoản vay

param(
    [string]$AdminToken = "",
    [int]$LoanId = 1,
    [string]$BaseUrl = "http://localhost:8082"
)

Write-Host "=== Test Admin Loan Status Update API ===" -ForegroundColor Cyan

if ($AdminToken -eq "") {
    Write-Host "Vui lòng cung cấp Admin JWT Token:" -ForegroundColor Yellow
    Write-Host "Usage: .\test-admin-loan-status.ps1 -AdminToken 'YOUR_JWT_TOKEN' -LoanId 1" -ForegroundColor Yellow
    exit 1
}

$headers = @{
    "Content-Type"  = "application/json"
    "Authorization" = "Bearer $AdminToken"
}

function Test-UpdateLoanStatus {
    param($Status, $Reason = $null)
    
    $body = @{ status = $Status }
    if ($Reason) {
        $body.reason = $Reason
    }
    
    $jsonBody = $body | ConvertTo-Json
    
    Write-Host "`n--- Testing: Update loan $LoanId to $Status ---" -ForegroundColor Green
    Write-Host "Request Body: $jsonBody"
    
    try {
        $response = Invoke-RestMethod -Uri "$BaseUrl/api/loans/$LoanId/status" -Method POST -Headers $headers -Body $jsonBody
        Write-Host "✅ Success!" -ForegroundColor Green
        Write-Host "Response: $($response | ConvertTo-Json -Depth 3)" -ForegroundColor White
    }
    catch {
        Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
        if ($_.Exception.Response) {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $responseBody = $reader.ReadToEnd()
            Write-Host "Error Response: $responseBody" -ForegroundColor Red
        }
    }
}

# Test cases
Write-Host "Loan Service URL: $BaseUrl" -ForegroundColor Cyan
Write-Host "Loan ID to test: $LoanId" -ForegroundColor Cyan

# 1. Test phê duyệt
Test-UpdateLoanStatus -Status "APPROVED"

# 2. Test từ chối với lý do
Test-UpdateLoanStatus -Status "REJECTED" -Reason "Thu nhập không đủ điều kiện vay"

# 3. Test trạng thái không hợp lệ
Test-UpdateLoanStatus -Status "INVALID_STATUS"

# 4. Test từ chối không có lý do (sẽ lỗi)
Test-UpdateLoanStatus -Status "REJECTED"

Write-Host "`n=== Test completed ===" -ForegroundColor Cyan
