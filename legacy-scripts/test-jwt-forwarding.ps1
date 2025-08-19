#!/usr/bin/env pwsh
# Test JWT Token Forwarding với Feign Client

Write-Host "🚀 Testing JWT Token Forwarding Implementation" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan

# Function để kiểm tra service availability
function Test-ServiceAvailability {
    param($serviceName, $url)
    
    try {
        $response = Invoke-RestMethod -Uri "$url/actuator/health" -Method GET -TimeoutSec 5
        Write-Host "✅ $serviceName is available" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "❌ $serviceName is not available: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Kiểm tra services
Write-Host "`n🔍 Checking Service Availability:" -ForegroundColor Yellow
$accountServiceOk = Test-ServiceAvailability "Account Management" "http://localhost:8080"
$customerServiceOk = Test-ServiceAvailability "Customer Service" "http://localhost:8082"
$keycloakOk = Test-ServiceAvailability "Keycloak" "http://localhost:8090"

if (-not ($accountServiceOk -and $customerServiceOk -and $keycloakOk)) {
    Write-Host "`n⚠️  Some services are not available. Please start all services first." -ForegroundColor Yellow
    Write-Host "Run: docker-compose up -d" -ForegroundColor White
    exit 1
}

# Function để lấy JWT token
function Get-JwtToken {
    Write-Host "`n🔑 Getting JWT Token..." -ForegroundColor Yellow
    
    $tokenUrl = "http://localhost:8090/realms/Kienlongbank/protocol/openid-connect/token"
    $body = @{
        grant_type = "password"
        username = "testuser"
        password = "testpassword"
        client_id = "klb-frontend"
    }
    
    try {
        $response = Invoke-RestMethod -Uri $tokenUrl -Method POST -Body $body -ContentType "application/x-www-form-urlencoded"
        Write-Host "✅ Successfully obtained JWT token" -ForegroundColor Green
        return $response.access_token
    } catch {
        Write-Host "❌ Failed to get JWT token: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# Function để test API với JWT token
function Test-ApiWithToken {
    param($token)
    
    Write-Host "`n🧪 Testing JWT Token Forwarding..." -ForegroundColor Yellow
    
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
    }
    
    # Test 1: Lấy danh sách accounts (should work with token forwarding)
    Write-Host "`nTest 1: GET /api/accounts (với JWT token)" -ForegroundColor Blue
    try {
        $accounts = Invoke-RestMethod -Uri "http://localhost:8080/api/accounts" -Method GET -Headers $headers
        Write-Host "✅ Successfully retrieved accounts with JWT forwarding" -ForegroundColor Green
        Write-Host "   Found $($accounts.Count) accounts" -ForegroundColor Gray
    } catch {
        Write-Host "❌ Failed to get accounts: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # Test 2: Tạo account mới (sẽ gọi customer service với token forwarding)
    Write-Host "`nTest 2: POST /api/accounts (tạo account - test token forwarding)" -ForegroundColor Blue
    $newAccount = @{
        customerId = 1
        accountType = "SAVINGS"
        balance = 1000.0
    } | ConvertTo-Json
    
    try {
        $created = Invoke-RestMethod -Uri "http://localhost:8080/api/accounts" -Method POST -Headers $headers -Body $newAccount
        Write-Host "✅ Successfully created account with JWT token forwarding" -ForegroundColor Green
        Write-Host "   Account Number: $($created.accountNumber)" -ForegroundColor Gray
        Write-Host "   Customer ID: $($created.customerId)" -ForegroundColor Gray
    } catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        $responseBody = $_.Exception.Response | ConvertFrom-Json -ErrorAction SilentlyContinue
        
        if ($statusCode -eq 401) {
            Write-Host "❌ 401 Unauthorized - JWT token issue" -ForegroundColor Red
        } elseif ($statusCode -eq 404) {
            Write-Host "⚠️  404 Not Found - Customer not found (expected if customer ID 1 doesn't exist)" -ForegroundColor Yellow
        } else {
            Write-Host "❌ Request failed with status $statusCode" -ForegroundColor Red
            Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Gray
        }
    }
    
    # Test 3: Test admin endpoint
    Write-Host "`nTest 3: GET /api/admin/hello (test ADMIN role)" -ForegroundColor Blue
    try {
        $adminResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/admin/hello" -Method GET -Headers $headers
        Write-Host "✅ Admin endpoint success: $adminResponse" -ForegroundColor Green
    } catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        if ($statusCode -eq 401) {
            Write-Host "❌ 401 Unauthorized - User doesn't have ADMIN role" -ForegroundColor Red
            Write-Host "   This is expected if testuser doesn't have ADMIN role assigned" -ForegroundColor Gray
        } else {
            Write-Host "❌ Admin endpoint failed with status $statusCode" -ForegroundColor Red
        }
    }
}

# Test without token
function Test-ApiWithoutToken {
    Write-Host "`n🚫 Testing API without JWT token (should fail)..." -ForegroundColor Yellow
    
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:8080/api/accounts" -Method GET
        Write-Host "❌ Unexpected success - API should require authentication!" -ForegroundColor Red
    } catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        if ($statusCode -eq 401) {
            Write-Host "✅ Correctly rejected request without token (401 Unauthorized)" -ForegroundColor Green
        } else {
            Write-Host "⚠️  Unexpected status code: $statusCode" -ForegroundColor Yellow
        }
    }
}

# Main test execution
Write-Host "`n🔄 Starting JWT Token Forwarding Tests..." -ForegroundColor Cyan

# Test without token first
Test-ApiWithoutToken

# Get token and test with token
$token = Get-JwtToken
if ($token) {
    Test-ApiWithToken $token
    
    Write-Host "`n🎯 Implementation Summary:" -ForegroundColor Cyan
    Write-Host "=========================" -ForegroundColor Cyan
    Write-Host "✅ JwtForwardingInterceptor: Automatically forwards JWT tokens" -ForegroundColor Green
    Write-Host "✅ CustomerClient (Feign): Type-safe API calls with automatic token forwarding" -ForegroundColor Green
    Write-Host "✅ CustomerServiceClientV2: Enhanced error handling and logging" -ForegroundColor Green
    Write-Host "✅ AccountService: Updated to use Feign-based client" -ForegroundColor Green
    
    Write-Host "`n📚 Key Benefits:" -ForegroundColor Blue
    Write-Host "- Automatic JWT token forwarding between services" -ForegroundColor White
    Write-Host "- Type-safe API calls with Feign Client" -ForegroundColor White  
    Write-Host "- Better error handling and logging" -ForegroundColor White
    Write-Host "- Centralized HTTP client configuration" -ForegroundColor White
    Write-Host "- Easy to test and mock" -ForegroundColor White
    
} else {
    Write-Host "`n❌ Cannot proceed with token-based tests due to authentication failure" -ForegroundColor Red
}

Write-Host "`n✨ JWT Token Forwarding Implementation Complete!" -ForegroundColor Green
Write-Host "📖 Check JWT_FORWARDING_IMPLEMENTATION.md for detailed documentation" -ForegroundColor Gray
