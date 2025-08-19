#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Quick API Test - Simple version
    
.DESCRIPTION
    Tool đơn giản để test nhanh các API endpoints
    
.EXAMPLE
    .\quick-api-test.ps1
    .\quick-api-test.ps1 -AdminTest
#>

param(
    [switch]$AdminTest,
    [switch]$Verbose
)

function Write-Status {
    param([string]$Message, [string]$Status)
    $color = switch ($Status) {
        "OK" { "Green" }
        "ERROR" { "Red" }
        "WARNING" { "Yellow" }
        "INFO" { "Cyan" }
        default { "White" }
    }
    Write-Host "[$Status] $Message" -ForegroundColor $color
}

function Get-Token {
    param([string]$Username = "testuser", [string]$Password = "password123")
    
    Write-Status "Getting JWT token for user: $Username..." "INFO"
    
    $tokenUrl = "http://localhost:8090/realms/Kienlongbank/protocol/openid-connect/token"
    $body = @{
        'grant_type' = 'password'
        'client_id'  = 'klb-frontend'
        'username'   = $Username
        'password'   = $Password
    }
    
    try {
        $response = Invoke-RestMethod -Uri $tokenUrl -Method POST -Body $body -ContentType "application/x-www-form-urlencoded" -TimeoutSec 10
        Write-Status "Token obtained successfully" "OK"
        
        if ($Verbose) {
            Write-Host "   Token length: $($response.access_token.Length) characters" -ForegroundColor Green
            Write-Host "   Token type: $($response.token_type)" -ForegroundColor Green
            Write-Host "   Expires in: $($response.expires_in) seconds" -ForegroundColor Green
        }
        
        return $response.access_token
    }
    catch {
        Write-Status "Failed to get token: $($_.Exception.Message)" "ERROR"
        return $null
    }
}

function Test-API {
    param([string]$Url, [string]$Method = "GET", [string]$Token = "", [object]$Body = $null, [string]$Description = "")
    
    Write-Host "`n🧪 $Description" -ForegroundColor Yellow
    Write-Host "   $Method $Url" -ForegroundColor Gray
    
    $headers = @{ 'Content-Type' = 'application/json' }
    if ($Token) {
        $headers['Authorization'] = "Bearer $Token"
        if ($Verbose) {
            Write-Host "   Using token (length: $($Token.Length))" -ForegroundColor Magenta
        }
    }
    
    try {
        $startTime = Get-Date
        
        $params = @{
            Uri        = $Url
            Method     = $Method
            Headers    = $headers
            TimeoutSec = 10
        }
        
        if ($Body) {
            $params.Body = ($Body | ConvertTo-Json -Depth 3)
        }
        
        $response = Invoke-RestMethod @params
        $duration = ((Get-Date) - $startTime).TotalMilliseconds
        
        Write-Status "SUCCESS (${duration}ms)" "OK"
        
        if ($Verbose -and $response) {
            Write-Host "   Response: $($response | ConvertTo-Json -Depth 2 -Compress)" -ForegroundColor Green
        }
        
        return $true
    }
    catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        $errorDetails = $_.Exception.Message
        
        if ($Verbose) {
            Write-Host "   Full error: $errorDetails" -ForegroundColor Red
            if ($_.Exception.Response) {
                Write-Host "   Response headers: $($_.Exception.Response.Headers)" -ForegroundColor Red
            }
        }
        
        Write-Status "FAILED ($statusCode): $errorDetails" "ERROR"
        return $false
    }
}

function Test-DatabaseConnection {
    param([string]$HostName, [int]$Port, [string]$Description)
    
    Write-Host "`n🧪 $Description" -ForegroundColor Yellow
    Write-Host "   Testing connection to ${HostName}:${Port}" -ForegroundColor Gray
    
    try {
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $tcpClient.ReceiveTimeout = 3000
        $tcpClient.SendTimeout = 3000
        $tcpClient.Connect($HostName, $Port)
        $tcpClient.Close()
        
        Write-Status "SUCCESS - Port is open" "OK"
        return $true
    }
    catch {
        Write-Status "FAILED - Cannot connect to port" "ERROR"
        return $false
    }
}

# Main execution
Write-Host @"
🏦 Quick API Test Tool - API Gateway Edition
============================================
Testing KLB Banking APIs via API Gateway (port 8080)
All requests are routed through the centralized gateway
"@ -ForegroundColor Blue

# Health checks first
Write-Host "`n🔍 Health Checks" -ForegroundColor Blue

# Check database connections
$dbResults = @{}
$databases = @(
    @{ hostname = "localhost"; port = 5432; name = "PostgreSQL Main DB" },
    @{ hostname = "localhost"; port = 5433; name = "PostgreSQL Customer DB" }
)

foreach ($db in $databases) {
    $result = Test-DatabaseConnection -HostName $db.hostname -Port $db.port -Description "Database connection - $($db.name)"
    $dbResults[$db.name] = $result
}

# Check API endpoints
$services = @(
    @{ url = "http://localhost:8080/api/health"; name = "API Gateway Public Health"; auth = $false },
    @{ url = "http://localhost:8090/realms/Kienlongbank"; name = "Keycloak Realm"; auth = $false }
)

$healthResults = @{}
foreach ($service in $services) {
    $result = Test-API -Url $service.url -Description "Health check - $($service.name)"
    $healthResults[$service.name] = $result
}

# Get token for authenticated tests
$username = if ($AdminTest) { "0901234567" } else { "0987654321" }
$password = if ($AdminTest) { "admin123" } else { "password123" }
$token = Get-Token -Username $username -Password $password

if (-not $token) {
    Write-Status "Cannot proceed without authentication token" "ERROR"
    exit 1
}

# Basic API tests
Write-Host "`n🔐 Authenticated API Tests (via API Gateway)" -ForegroundColor Blue

$apiTests = @(
    @{
        url         = "http://localhost:8080/api/accounts"
        method      = "GET"
        description = "Get accounts (via Gateway)"
    },
    @{
        url         = "http://localhost:8080/api/customers"
        method      = "GET"
        description = "Get customers (via Gateway)"
    },
    @{
        url         = "http://localhost:8080/api/loans/my-loans"
        method      = "GET"
        description = "Get my loans (via Gateway)"
    }
)

if ($AdminTest) {
    # Add admin-specific tests - all via API Gateway
    $apiTests += @(
        @{
            url         = "http://localhost:8080/api/transactions"
            method      = "GET"
            description = "Get all transactions (Admin via Gateway)"
        },
        @{
            url         = "http://localhost:8080/api/loans"
            method      = "GET"
            description = "Get all loans (Admin via Gateway)"
        },
        @{
            url         = "http://localhost:8080/api/notifications"
            method      = "GET"
            description = "Get notifications (Admin via Gateway)"
        }
    )
}

$apiResults = @{}
foreach ($test in $apiTests) {
    $result = Test-API -Url $test.url -Method $test.method -Token $token -Description $test.description
    $apiResults[$test.description] = $result
}

# Create test data (if admin) - all via API Gateway
if ($AdminTest) {
    Write-Host "`n✨ Create Test Data (via API Gateway)" -ForegroundColor Blue
    
    # Create customer
    $customerData = @{
        firstName   = "Test"
        lastName    = "Customer"
        email       = "test.customer@klb.com"
        phoneNumber = "0987654321"
        address     = "123 Test Street"
    }
    
    $createCustomer = Test-API -Url "http://localhost:8080/api/customers" -Method "POST" -Token $token -Body $customerData -Description "Create test customer (via Gateway)"
    
    # Create account
    $accountData = @{
        customerId     = 1
        accountType    = "SAVINGS"
        initialBalance = 5000.0
    }
    
    $createAccount = Test-API -Url "http://localhost:8080/api/accounts" -Method "POST" -Token $token -Body $accountData -Description "Create test account (via Gateway)"
    
    # Apply for loan
    $loanData = @{
        customerId = 1
        amount     = 25000.0
        purpose    = "Car purchase"
        termMonths = 36
    }
    
    $applyLoan = Test-API -Url "http://localhost:8080/api/loans/apply" -Method "POST" -Token $token -Body $loanData -Description "Apply for test loan (via Gateway)"
}

# Summary
Write-Host "`n📊 Test Summary" -ForegroundColor Blue
Write-Host "=" * 40

$totalTests = $dbResults.Count + $healthResults.Count + $apiResults.Count
$successCount = ($dbResults.Values + $healthResults.Values + $apiResults.Values | Where-Object { $_ -eq $true }).Count
$failCount = $totalTests - $successCount

Write-Host "Database Tests: $($dbResults.Count) (Passed: $(($dbResults.Values | Where-Object { $_ -eq $true }).Count))" -ForegroundColor Cyan
Write-Host "Health Tests: $($healthResults.Count) (Passed: $(($healthResults.Values | Where-Object { $_ -eq $true }).Count))" -ForegroundColor Cyan
Write-Host "API Tests: $($apiResults.Count) (Passed: $(($apiResults.Values | Where-Object { $_ -eq $true }).Count))" -ForegroundColor Cyan
Write-Host "-" * 40
Write-Host "Total Tests: $totalTests" -ForegroundColor White
Write-Host "Passed: $successCount" -ForegroundColor Green
Write-Host "Failed: $failCount" -ForegroundColor Red

if ($failCount -eq 0) {
    Write-Status "All tests passed! ✨" "OK"
}
else {
    Write-Status "Some tests failed. Check the logs above." "WARNING"
}

Write-Host "`n💡 Tips:" -ForegroundColor Yellow
Write-Host "  - Use -AdminTest for admin user testing" 
Write-Host "  - Use -Verbose for detailed response output"
Write-Host "  - Make sure Docker services are running: docker-compose up -d"
Write-Host "  - All APIs now route through API Gateway (port 8080)"
Write-Host "  - Check 'docker-compose ps' to see service status"
Write-Host "  - Gateway routes: /api/customers, /api/accounts, /api/loans, /api/notifications"
