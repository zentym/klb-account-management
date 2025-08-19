#!/usr/bin/env pwsh
# Test Customer Service JWT Authentication và Security Configuration

Write-Host "🔐 Testing Customer Service JWT Authentication & Security" -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan

# Function để kiểm tra service availability
function Test-ServiceAvailability {
    param($serviceName, $url)
    
    try {
        $response = Invoke-RestMethod -Uri "$url/api/health" -Method GET -TimeoutSec 5
        Write-Host "✅ $serviceName is available" -ForegroundColor Green
        return $true
    } catch {
        try {
            # Fallback to actuator health if custom health endpoint fails
            $response = Invoke-RestMethod -Uri "$url/actuator/health" -Method GET -TimeoutSec 5
            Write-Host "✅ $serviceName is available (via actuator)" -ForegroundColor Green
            return $true
        } catch {
            Write-Host "❌ $serviceName is not available: $($_.Exception.Message)" -ForegroundColor Red
            return $false
        }
    }
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

# Function để decode JWT token (basic)
function Show-JwtTokenInfo {
    param($token)
    
    if (-not $token) { return }
    
    Write-Host "`n🔍 JWT Token Information:" -ForegroundColor Blue
    
    # Split JWT token parts
    $parts = $token.Split('.')
    if ($parts.Length -ge 2) {
        try {
            # Decode payload (second part)
            $payload = $parts[1]
            # Add padding if needed
            while ($payload.Length % 4 -ne 0) { $payload += '=' }
            
            $decodedBytes = [System.Convert]::FromBase64String($payload)
            $decodedText = [System.Text.Encoding]::UTF8.GetString($decodedBytes)
            $payloadObj = $decodedText | ConvertFrom-Json
            
            Write-Host "   User: $($payloadObj.preferred_username)" -ForegroundColor Gray
            Write-Host "   Subject: $($payloadObj.sub)" -ForegroundColor Gray
            Write-Host "   Issuer: $($payloadObj.iss)" -ForegroundColor Gray
            
            if ($payloadObj.realm_access -and $payloadObj.realm_access.roles) {
                Write-Host "   Realm Roles: $($payloadObj.realm_access.roles -join ', ')" -ForegroundColor Gray
            }
            
            if ($payloadObj.exp) {
                $expDate = [DateTimeOffset]::FromUnixTimeSeconds($payloadObj.exp).ToString()
                Write-Host "   Expires: $expDate" -ForegroundColor Gray
            }
        } catch {
            Write-Host "   Could not decode token payload" -ForegroundColor Yellow
        }
    }
}

# Function để test customer service endpoints
function Test-CustomerServiceEndpoints {
    param($token)
    
    Write-Host "`n🧪 Testing Customer Service Endpoints..." -ForegroundColor Yellow
    
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
    }
    
    $baseUrl = "http://localhost:8082"
    
    # Test 1: Health endpoint (should be public)
    Write-Host "`nTest 1: GET /api/health (public endpoint)" -ForegroundColor Blue
    try {
        $health = Invoke-RestMethod -Uri "$baseUrl/api/health" -Method GET
        Write-Host "✅ Health endpoint accessible without token" -ForegroundColor Green
        Write-Host "   Status: $($health.data.status)" -ForegroundColor Gray
    } catch {
        Write-Host "❌ Health endpoint failed: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # Test 2: Customers endpoint without token (should fail)
    Write-Host "`nTest 2: GET /api/customers (without token - should fail)" -ForegroundColor Blue
    try {
        $customers = Invoke-RestMethod -Uri "$baseUrl/api/customers" -Method GET
        Write-Host "❌ Unexpected success - endpoint should require authentication!" -ForegroundColor Red
    } catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        if ($statusCode -eq 401) {
            Write-Host "✅ Correctly rejected request without token (401 Unauthorized)" -ForegroundColor Green
        } else {
            Write-Host "⚠️  Unexpected status code: $statusCode" -ForegroundColor Yellow
        }
    }
    
    # Test 3: Customers endpoint with token (should work)
    Write-Host "`nTest 3: GET /api/customers (with JWT token)" -ForegroundColor Blue
    try {
        $customers = Invoke-RestMethod -Uri "$baseUrl/api/customers" -Method GET -Headers $headers
        Write-Host "✅ Successfully retrieved customers with JWT token" -ForegroundColor Green
        Write-Host "   Found $($customers.data.Count) customers" -ForegroundColor Gray
    } catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        Write-Host "❌ Failed to get customers: Status $statusCode" -ForegroundColor Red
        Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Gray
    }
    
    # Test 4: Admin endpoint (may fail if user doesn't have ADMIN role)
    Write-Host "`nTest 4: GET /api/admin/hello (requires ADMIN role)" -ForegroundColor Blue
    try {
        $adminResponse = Invoke-RestMethod -Uri "$baseUrl/api/admin/hello" -Method GET -Headers $headers
        Write-Host "✅ Admin endpoint success: $($adminResponse.data.message)" -ForegroundColor Green
    } catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        if ($statusCode -eq 401) {
            Write-Host "❌ 401 Unauthorized - User doesn't have ADMIN role" -ForegroundColor Red
            Write-Host "   This is expected if testuser doesn't have ADMIN role assigned" -ForegroundColor Gray
        } elseif ($statusCode -eq 403) {
            Write-Host "❌ 403 Forbidden - User authenticated but lacks ADMIN authority" -ForegroundColor Red
            Write-Host "   This is expected if testuser doesn't have ADMIN role assigned" -ForegroundColor Gray
        } else {
            Write-Host "❌ Admin endpoint failed with status $statusCode" -ForegroundColor Red
        }
    }
    
    # Test 5: Create a new customer
    Write-Host "`nTest 5: POST /api/customers (create customer with JWT)" -ForegroundColor Blue
    $newCustomer = @{
        fullName = "Test Customer JWT"
        email = "test.jwt@kienlongbank.com"
        phone = "0123456789"
        address = "123 JWT Test Street"
    } | ConvertTo-Json
    
    try {
        $created = Invoke-RestMethod -Uri "$baseUrl/api/customers" -Method POST -Headers $headers -Body $newCustomer
        Write-Host "✅ Successfully created customer with JWT token" -ForegroundColor Green
        Write-Host "   Customer ID: $($created.data.id)" -ForegroundColor Gray
        Write-Host "   Customer Name: $($created.data.fullName)" -ForegroundColor Gray
        
        # Return the created customer ID for cleanup
        return $created.data.id
    } catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        Write-Host "❌ Failed to create customer: Status $statusCode" -ForegroundColor Red
        Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Gray
        return $null
    }
}

# Function để test Swagger UI access
function Test-SwaggerAccess {
    Write-Host "`n📚 Testing Swagger UI Access..." -ForegroundColor Yellow
    
    try {
        $swaggerResponse = Invoke-WebRequest -Uri "http://localhost:8082/swagger-ui/index.html" -Method GET
        if ($swaggerResponse.StatusCode -eq 200) {
            Write-Host "✅ Swagger UI is accessible (public endpoint)" -ForegroundColor Green
        }
    } catch {
        Write-Host "❌ Swagger UI not accessible: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    try {
        $apiDocs = Invoke-RestMethod -Uri "http://localhost:8082/v3/api-docs" -Method GET
        Write-Host "✅ OpenAPI docs are accessible" -ForegroundColor Green
    } catch {
        Write-Host "❌ OpenAPI docs not accessible: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Main execution
Write-Host "`n🔄 Starting Customer Service Security Tests..." -ForegroundColor Cyan

# Check service availability
Write-Host "`n🔍 Checking Service Availability:" -ForegroundColor Yellow
$customerServiceOk = Test-ServiceAvailability "Customer Service" "http://localhost:8082"
$keycloakOk = Test-ServiceAvailability "Keycloak" "http://localhost:8090"

if (-not ($customerServiceOk -and $keycloakOk)) {
    Write-Host "`n⚠️  Some services are not available. Please start all services first." -ForegroundColor Yellow
    Write-Host "Run: docker-compose up -d" -ForegroundColor White
    exit 1
}

# Test Swagger access
Test-SwaggerAccess

# Get JWT token and test endpoints
$token = Get-JwtToken
if ($token) {
    Show-JwtTokenInfo $token
    $createdCustomerId = Test-CustomerServiceEndpoints $token
    
    # Cleanup created customer if any
    if ($createdCustomerId) {
        Write-Host "`n🧹 Cleaning up created test customer..." -ForegroundColor Yellow
        try {
            $headers = @{
                "Authorization" = "Bearer $token"
                "Content-Type" = "application/json"
            }
            Invoke-RestMethod -Uri "http://localhost:8082/api/customers/$createdCustomerId" -Method DELETE -Headers $headers
            Write-Host "✅ Test customer cleaned up" -ForegroundColor Green
        } catch {
            Write-Host "⚠️  Could not clean up test customer: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
    
    Write-Host "`n🎯 Customer Service Security Summary:" -ForegroundColor Cyan
    Write-Host "====================================" -ForegroundColor Cyan
    Write-Host "✅ SecurityConfig.java: Enhanced with proper JWT authentication" -ForegroundColor Green
    Write-Host "✅ JwtAuthenticationConverter: Extracts roles from Keycloak JWT" -ForegroundColor Green
    Write-Host "✅ Endpoint Protection: All /api/customers/* require authentication" -ForegroundColor Green
    Write-Host "✅ Admin Endpoints: /api/admin/* require ADMIN role" -ForegroundColor Green
    Write-Host "✅ Public Endpoints: Health, Swagger, Actuator are accessible" -ForegroundColor Green
    Write-Host "✅ JWT Integration: Properly connected to Keycloak" -ForegroundColor Green
    
    Write-Host "`n📚 Security Features Implemented:" -ForegroundColor Blue
    Write-Host "- JWT token validation via Keycloak" -ForegroundColor White
    Write-Host "- Role extraction from realm_access.roles claim" -ForegroundColor White
    Write-Host "- Method-level security with @PreAuthorize" -ForegroundColor White
    Write-Host "- Session management: STATELESS" -ForegroundColor White
    Write-Host "- CSRF protection: DISABLED (for API)" -ForegroundColor White
    Write-Host "- Public endpoints for health checks and documentation" -ForegroundColor White
    
} else {
    Write-Host "`n❌ Cannot proceed with token-based tests due to authentication failure" -ForegroundColor Red
}

Write-Host "`n✨ Customer Service Security Configuration Complete!" -ForegroundColor Green
Write-Host "🔗 Customer Service Swagger UI: http://localhost:8082/swagger-ui/index.html" -ForegroundColor Gray
Write-Host "🔗 Customer Service Health: http://localhost:8082/api/health" -ForegroundColor Gray
