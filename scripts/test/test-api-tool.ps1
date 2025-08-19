#!/usr/bin/env pwsh
<#
.SYNOPSIS
    KLB Banking API Testing Tool
    
.DESCRIPTION
    Tool kiểm tra tất cả API endpoints của KLB Banking System với JWT authentication
    
.PARAMETER Service
    Service cần test: all, main, customer, loan, notification
    
.PARAMETER Endpoint
    Endpoint cụ thể để test
    
.PARAMETER Method
    HTTP method: GET, POST, PUT, DELETE
    
.PARAMETER Token
    JWT token để sử dụng (nếu không có sẽ tự động lấy)
    
.PARAMETER Username
    Username để lấy token (default: testuser)
    
.PARAMETER Password
    Password để lấy token (default: password123)
    
.PARAMETER Verbose
    Hiển thị thông tin chi tiết
    
.EXAMPLE
    .\test-api-tool.ps1 -Service all
    .\test-api-tool.ps1 -Service main -Endpoint "/api/accounts" -Method GET
    .\test-api-tool.ps1 -Service customer -Username "admin" -Password "admin123"
#>

param(
    [Parameter(Mandatory = $false)]
    [ValidateSet("all", "gateway", "main", "customer", "loan")]
    [string]$Service = "all",
    
    [Parameter(Mandatory = $false)]
    [string]$Endpoint = "",
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("GET", "POST", "PUT", "DELETE")]
    [string]$Method = "GET",
    
    [Parameter(Mandatory = $false)]
    [string]$Token = "",
    
    [Parameter(Mandatory = $false)]
    [string]$Username = "testuser",
    
    [Parameter(Mandatory = $false)]
    [string]$Password = "password123",
    
    [Parameter(Mandatory = $false)]
    [switch]$ShowDetails
)

# Colors for output
$Green = [System.ConsoleColor]::Green
$Red = [System.ConsoleColor]::Red
$Yellow = [System.ConsoleColor]::Yellow
$Blue = [System.ConsoleColor]::Blue
$Cyan = [System.ConsoleColor]::Cyan

# Service configurations
$Services = @{
    "gateway"  = @{
        "name"      = "API Gateway"
        "baseUrl"   = "http://localhost:8080"
        "endpoints" = @(
            @{ "path" = "/api/accounts"; "method" = "GET"; "auth" = $true; "description" = "Get all accounts (ADMIN only)" },
            @{ "path" = "/api/accounts"; "method" = "POST"; "auth" = $true; "description" = "Create account"; "body" = @{
                    "customerId"     = 1;
                    "accountType"    = "SAVINGS";
                    "initialBalance" = 1000.0
                }
            },
            @{ "path" = "/api/transactions"; "method" = "GET"; "auth" = $true; "description" = "Get all transactions (ADMIN only)" },
            @{ "path" = "/api/customers"; "method" = "GET"; "auth" = $true; "description" = "Get all customers" },
            @{ "path" = "/api/loans"; "method" = "GET"; "auth" = $true; "description" = "Get all loans (ADMIN only)" }
        )
    }
    "main"     = @{
        "name"      = "Account Management Service (via Gateway)"
        "baseUrl"   = "http://localhost:8080"
        "endpoints" = @(
            @{ "path" = "/api/accounts"; "method" = "GET"; "auth" = $true; "description" = "Get all accounts (ADMIN only)" },
            @{ "path" = "/api/accounts"; "method" = "POST"; "auth" = $true; "description" = "Create account"; "body" = @{
                    "customerId"     = 1;
                    "accountType"    = "SAVINGS";
                    "initialBalance" = 1000.0
                }
            },
            @{ "path" = "/api/transactions"; "method" = "GET"; "auth" = $true; "description" = "Get all transactions (ADMIN only)" },
            @{ "path" = "/api/transactions"; "method" = "POST"; "auth" = $true; "description" = "Create transaction"; "body" = @{
                    "fromAccountId" = 1;
                    "toAccountId"   = 2;
                    "amount"        = 100.0;
                    "description"   = "Test transfer"
                }
            }
        )
    }
    "customer" = @{
        "name"      = "Customer Service (via Gateway)"
        "baseUrl"   = "http://localhost:8080"
        "endpoints" = @(
            @{ "path" = "/api/customers"; "method" = "GET"; "auth" = $true; "description" = "Get all customers" },
            @{ "path" = "/api/customers"; "method" = "POST"; "auth" = $true; "description" = "Create customer (ADMIN only)"; "body" = @{
                    "firstName"   = "Test";
                    "lastName"    = "User";
                    "email"       = "test@example.com";
                    "phoneNumber" = "0123456789"
                }
            }
        )
    }
    "loan"     = @{
        "name"      = "Loan Service (via Gateway)"
        "baseUrl"   = "http://localhost:8080"
        "endpoints" = @(
            @{ "path" = "/api/loans"; "method" = "GET"; "auth" = $true; "description" = "Get all loans (ADMIN only)" },
            @{ "path" = "/api/loans/apply"; "method" = "POST"; "auth" = $true; "description" = "Apply for loan"; "body" = @{
                    "customerId" = 1;
                    "amount"     = 50000.0;
                    "purpose"    = "Home renovation";
                    "termMonths" = 24
                }
            }
        )
    }
}

function Write-ColoredText {
    param([string]$Text, [System.ConsoleColor]$Color)
    $originalColor = [Console]::ForegroundColor
    [Console]::ForegroundColor = $Color
    Write-Host $Text
    [Console]::ForegroundColor = $originalColor
}

function Get-KeycloakToken {
    param([string]$Username, [string]$Password)
    
    Write-ColoredText "🔑 Getting JWT token from Keycloak..." $Blue
    
    $tokenUrl = "http://localhost:8090/realms/Kienlongbank/protocol/openid-connect/token"
    $body = @{
        'grant_type' = 'password'
        'client_id'  = 'klb-frontend'
        'username'   = $Username
        'password'   = $Password
    }
    
    try {
        $response = Invoke-RestMethod -Uri $tokenUrl -Method POST -Body $body -ContentType "application/x-www-form-urlencoded"
        Write-ColoredText "✅ Token obtained successfully" $Green
        return $response.access_token
    }
    catch {
        Write-ColoredText "❌ Failed to get token: $($_.Exception.Message)" $Red
        return $null
    }
}

function Test-Endpoint {
    param(
        [string]$BaseUrl,
        [hashtable]$Endpoint,
        [string]$Token
    )
    
    $url = $BaseUrl + $Endpoint.path
    $method = $Endpoint.method
    $needsAuth = $Endpoint.auth
    $description = $Endpoint.description
    
    Write-Host ""
    Write-ColoredText "🧪 Testing: $method $url" $Cyan
    Write-ColoredText "   Description: $description" $Yellow
    
    # Prepare headers
    $headers = @{
        'Content-Type' = 'application/json'
    }
    
    if ($needsAuth -and $Token) {
        $headers['Authorization'] = "Bearer $Token"
    }
    
    # Prepare body
    $requestBody = $null
    if ($Endpoint.body) {
        $requestBody = $Endpoint.body | ConvertTo-Json -Depth 3
        if ($ShowDetails) {
            Write-ColoredText "   Request Body: $requestBody" $Yellow
        }
    }
    
    try {
        $startTime = Get-Date
        
        if ($method -eq "GET") {
            $response = Invoke-RestMethod -Uri $url -Method $method -Headers $headers -ErrorAction Stop
        }
        elseif ($method -in @("POST", "PUT") -and $requestBody) {
            $response = Invoke-RestMethod -Uri $url -Method $method -Headers $headers -Body $requestBody -ErrorAction Stop
        }
        else {
            $response = Invoke-RestMethod -Uri $url -Method $method -Headers $headers -ErrorAction Stop
        }
        
        $endTime = Get-Date
        $duration = ($endTime - $startTime).TotalMilliseconds
        
        Write-ColoredText "   ✅ SUCCESS (${duration}ms)" $Green
        
        if ($ShowDetails -and $response) {
            $responseJson = $response | ConvertTo-Json -Depth 3
            Write-ColoredText "   Response: $responseJson" $Green
        }
        
        return @{ "success" = $true; "duration" = $duration; "response" = $response }
    }
    catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        $errorMessage = $_.Exception.Message
        
        if ($statusCode -eq 401) {
            Write-ColoredText "   ⚠️ UNAUTHORIZED (401) - Token may be invalid or expired" $Yellow
        }
        elseif ($statusCode -eq 403) {
            Write-ColoredText "   ⚠️ FORBIDDEN (403) - Insufficient permissions" $Yellow
        }
        elseif ($statusCode -eq 404) {
            Write-ColoredText "   ⚠️ NOT FOUND (404) - Endpoint not found" $Yellow
        }
        else {
            Write-ColoredText "   ❌ ERROR ($statusCode): $errorMessage" $Red
        }
        
        return @{ "success" = $false; "statusCode" = $statusCode; "error" = $errorMessage }
    }
}

function Test-Service {
    param([string]$ServiceName, [string]$Token)
    
    if (-not $Services.ContainsKey($ServiceName)) {
        Write-ColoredText "❌ Unknown service: $ServiceName" $Red
        return
    }
    
    $service = $Services[$ServiceName]
    Write-ColoredText "`n🚀 Testing $($service.name) - $($service.baseUrl)" $Blue
    Write-Host "=" * 60
    
    $results = @{
        "total"        = 0
        "success"      = 0
        "failed"       = 0
        "unauthorized" = 0
        "forbidden"    = 0
    }
    
    foreach ($endpoint in $service.endpoints) {
        $results.total++
        $result = Test-Endpoint -BaseUrl $service.baseUrl -Endpoint $endpoint -Token $Token
        
        if ($result.success) {
            $results.success++
        }
        else {
            $results.failed++
            if ($result.statusCode -eq 401) { $results.unauthorized++ }
            if ($result.statusCode -eq 403) { $results.forbidden++ }
        }
    }
    
    Write-Host ""
    Write-ColoredText "📊 Results for $($service.name):" $Blue
    Write-ColoredText "   Total: $($results.total)" $Cyan
    Write-ColoredText "   Success: $($results.success)" $Green
    Write-ColoredText "   Failed: $($results.failed)" $Red
    Write-ColoredText "   Unauthorized: $($results.unauthorized)" $Yellow
    Write-ColoredText "   Forbidden: $($results.forbidden)" $Yellow
}

function Show-ServiceStatus {
    Write-ColoredText "🔍 Checking service status..." $Blue
    Write-Host ""
    
    # Check API Gateway
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8080/" -Method GET -TimeoutSec 5 -ErrorAction SilentlyContinue
        # 401 means gateway is up but requires auth
        if ($response.StatusCode -eq 200 -or $_.Exception.Response.StatusCode.Value__ -eq 401) {
            Write-ColoredText "✅ API Gateway - UP" $Green
        }
    }
    catch {
        if ($_.Exception.Response.StatusCode.Value__ -eq 401) {
            Write-ColoredText "✅ API Gateway - UP (requires authentication)" $Green
        }
        else {
            Write-ColoredText "❌ API Gateway - DOWN" $Red
        }
    }
    
    # Check Keycloak
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:8090/realms/Kienlongbank/.well-known/openid-configuration" -Method GET -TimeoutSec 5
        Write-ColoredText "✅ Keycloak - UP" $Green
    }
    catch {
        Write-ColoredText "❌ Keycloak - DOWN" $Red
    }
}

# Main execution
Write-ColoredText @"
🏦 KLB Banking API Testing Tool
================================
Services: main (8080), customer (8082), loan (8083), notification (8084)
"@ $Blue

# Show service status first
Show-ServiceStatus

# Get token if needed
$jwtToken = $Token
if (-not $jwtToken -and ($Service -ne "notification" -or $Service -eq "all")) {
    $jwtToken = Get-KeycloakToken -Username $Username -Password $Password
    if (-not $jwtToken) {
        Write-ColoredText "❌ Cannot proceed without token" $Red
        exit 1
    }
}

# Test specific endpoint if provided
if ($Endpoint -and $Service -ne "all") {
    if (-not $Services.ContainsKey($Service)) {
        Write-ColoredText "❌ Unknown service: $Service" $Red
        exit 1
    }
    
    $service = $Services[$Service]
    $customEndpoint = @{
        "path"        = $Endpoint
        "method"      = $Method
        "auth"        = $true
        "description" = "Custom endpoint test"
    }
    
    Write-ColoredText "`n🎯 Testing custom endpoint..." $Blue
    Test-Endpoint -BaseUrl $service.baseUrl -Endpoint $customEndpoint -Token $jwtToken
    exit 0
}

# Test services
if ($Service -eq "all") {
    foreach ($serviceName in @("gateway", "main", "customer", "loan")) {
        Test-Service -ServiceName $serviceName -Token $jwtToken
    }
}
else {
    Test-Service -ServiceName $Service -Token $jwtToken
}

Write-Host ""
Write-ColoredText "🎉 API testing completed!" $Green
Write-ColoredText "💡 Use -ShowDetails flag for detailed response output" $Yellow
Write-ColoredText "💡 Use -Service <name> to test specific service" $Yellow
Write-ColoredText "💡 Use -Endpoint '/api/path' -Method GET to test custom endpoint" $Yellow
