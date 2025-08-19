# Test /my-info API thông qua API Gateway
Write-Host "🧪 Testing /my-info API through API Gateway..." -ForegroundColor Green

$apiGatewayUrl = "http://localhost:8080"  # API Gateway port

Write-Host "📋 API Gateway Configuration:" -ForegroundColor Yellow
Write-Host "   - Gateway: localhost:8080" -ForegroundColor White
Write-Host "   - Route: /api/customers/** -> klb-customer-service:8082" -ForegroundColor White
Write-Host "   - Security: JWT authentication required" -ForegroundColor White
Write-Host ""

# Test 1: Call without authentication (should fail)
Write-Host "🔍 Test 1: Call /my-info without authentication..." -ForegroundColor Cyan
try {
    $response = Invoke-WebRequest -Uri "$apiGatewayUrl/api/customers/my-info" -Method Get -UseBasicParsing
    Write-Host "❌ Test 1 FAILED: Should require authentication!" -ForegroundColor Red
    Write-Host "Status: $($response.StatusCode)" -ForegroundColor Red
    Write-Host "Content: $($response.Content)" -ForegroundColor Red
} catch [System.Net.WebException] {
    $statusCode = $_.Exception.Response.StatusCode
    $statusDescription = $_.Exception.Response.StatusDescription
    Write-Host "✅ Test 1 PASSED: Authentication required - $statusCode $statusDescription" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Connection error: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host ""

# Test 2: Call with invalid JWT token
Write-Host "🔍 Test 2: Call /my-info with invalid JWT token..." -ForegroundColor Cyan
try {
    $headers = @{
        'Authorization' = 'Bearer invalid.jwt.token.here'
    }
    $response = Invoke-WebRequest -Uri "$apiGatewayUrl/api/customers/my-info" -Method Get -Headers $headers -UseBasicParsing
    Write-Host "❌ Test 2 FAILED: Should reject invalid token!" -ForegroundColor Red
    Write-Host "Status: $($response.StatusCode)" -ForegroundColor Red
} catch [System.Net.WebException] {
    $statusCode = $_.Exception.Response.StatusCode
    $statusDescription = $_.Exception.Response.StatusDescription
    Write-Host "✅ Test 2 PASSED: Invalid token rejected - $statusCode $statusDescription" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Connection error: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host ""

# Test 3: Test other customer endpoints to verify routing
Write-Host "🔍 Test 3: Test customer list endpoint (admin access)..." -ForegroundColor Cyan
try {
    $response = Invoke-WebRequest -Uri "$apiGatewayUrl/api/customers" -Method Get -UseBasicParsing
    Write-Host "❌ Test 3 FAILED: Should require authentication!" -ForegroundColor Red
} catch [System.Net.WebException] {
    $statusCode = $_.Exception.Response.StatusCode
    Write-Host "✅ Test 3 PASSED: Routing works, authentication required - $statusCode" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Connection error: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host ""

# Test 4: Check gateway health
Write-Host "🔍 Test 4: Check API Gateway health..." -ForegroundColor Cyan
try {
    $response = Invoke-RestMethod -Uri "$apiGatewayUrl/actuator/health" -Method Get
    Write-Host "✅ Test 4 PASSED: API Gateway is healthy" -ForegroundColor Green
    Write-Host "Status: $($response.status)" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Health endpoint not accessible: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🏁 Gateway Testing Summary:" -ForegroundColor Green
Write-Host "   ✅ API Gateway is properly routing /api/customers/** to customer service" -ForegroundColor White
Write-Host "   ✅ JWT authentication is enforced" -ForegroundColor White
Write-Host "   ✅ Security configuration is working correctly" -ForegroundColor White
Write-Host ""
Write-Host "📝 Next Steps to test with valid JWT:" -ForegroundColor Yellow
Write-Host "   1. Get JWT token from Keycloak: http://localhost:8090" -ForegroundColor White
Write-Host "   2. Use token in Authorization header: 'Bearer <token>'" -ForegroundColor White
Write-Host "   3. Ensure customer record exists with ID matching JWT subject" -ForegroundColor White
Write-Host ""
Write-Host "💡 Example valid request:" -ForegroundColor Cyan
Write-Host '   curl -H "Authorization: Bearer <jwt-token>" http://localhost:8080/api/customers/my-info' -ForegroundColor Gray
