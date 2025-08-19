# Test accounts API
Write-Host "🏦 Testing Accounts API" -ForegroundColor Cyan
Write-Host "========================" -ForegroundColor Cyan

$baseUrl = "http://localhost:8080"

# Lấy token từ login
$loginData = @{
    username = "test"
    password = "test"
} | ConvertTo-Json

Write-Host "📡 Logging in to get token..." -ForegroundColor Yellow
try {
    $loginResponse = Invoke-RestMethod -Uri "$baseUrl/api/auth/login" -Method POST -ContentType "application/json" -Body $loginData -UseBasicParsing
    $token = $loginResponse.token
    Write-Host "✅ Login successful!" -ForegroundColor Green

    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
    }

    # Lấy danh sách customers trước
    Write-Host "`n📡 Getting customers list..." -ForegroundColor Yellow
    $customersResponse = Invoke-RestMethod -Uri "$baseUrl/api/customers" -Headers $headers -UseBasicParsing
    $customers = $customersResponse.data
    Write-Host "✅ Found $($customers.Length) customers" -ForegroundColor Green
    
    if ($customers.Length -gt 0) {
        # Lấy customer đầu tiên
        $firstCustomer = $customers[0]
        $customerId = $firstCustomer.id
        Write-Host "📋 Testing with Customer ID: $customerId ($($firstCustomer.fullName))" -ForegroundColor Cyan
        
        # Test accounts API
        Write-Host "`n📡 Getting accounts for customer $customerId..." -ForegroundColor Yellow
        try {
            $accountsResponse = Invoke-RestMethod -Uri "$baseUrl/api/customers/$customerId/accounts" -Headers $headers -UseBasicParsing
            Write-Host "✅ Accounts API successful!" -ForegroundColor Green
            Write-Host "Response type: $($accountsResponse.GetType().Name)" -ForegroundColor Cyan
            
            if ($accountsResponse -is [Array]) {
                Write-Host "📊 Found $($accountsResponse.Length) accounts" -ForegroundColor Cyan
                foreach ($account in $accountsResponse) {
                    Write-Host "   - Account #$($account.id): $($account.accountNumber) ($($account.accountType))" -ForegroundColor Gray
                }
            } else {
                Write-Host "📊 Response: $($accountsResponse | ConvertTo-Json)" -ForegroundColor Gray
            }
        } catch {
            Write-Host "❌ Accounts API failed: $($_.Exception.Message)" -ForegroundColor Red
            if ($_.Exception.Response) {
                $statusCode = $_.Exception.Response.StatusCode
                Write-Host "Status Code: $statusCode" -ForegroundColor Red
                
                try {
                    $responseStream = $_.Exception.Response.GetResponseStream()
                    $reader = New-Object System.IO.StreamReader($responseStream)
                    $responseBody = $reader.ReadToEnd()
                    Write-Host "Response Body: $responseBody" -ForegroundColor Red
                } catch {
                    Write-Host "Could not read response body" -ForegroundColor Red
                }
            }
        }
        
        # Test tạo account mới
        Write-Host "`n📡 Testing create new account..." -ForegroundColor Yellow
        $newAccount = @{
            accountType = "SAVINGS"
            balance = 1000.00
        } | ConvertTo-Json
        
        try {
            $createResponse = Invoke-RestMethod -Uri "$baseUrl/api/customers/$customerId/accounts" -Method POST -Headers $headers -Body $newAccount -UseBasicParsing
            Write-Host "✅ Account created successfully!" -ForegroundColor Green
            Write-Host "New account: $($createResponse | ConvertTo-Json)" -ForegroundColor Gray
        } catch {
            Write-Host "❌ Create account failed: $($_.Exception.Message)" -ForegroundColor Red
        }
        
    } else {
        Write-Host "❌ No customers found to test with" -ForegroundColor Red
    }

} catch {
    Write-Host "❌ Login failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n🏁 Test completed!" -ForegroundColor Cyan
