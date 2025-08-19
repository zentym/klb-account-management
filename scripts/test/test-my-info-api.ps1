# Test script for /my-info API endpoint
Write-Host "🧪 Testing /my-info API endpoint..." -ForegroundColor Green

# Test URL
$baseUrl = "http://localhost:8080"  # API Gateway
$customerServiceUrl = "http://localhost:8082"  # Direct to customer service

Write-Host "📋 Testing scenarios:" -ForegroundColor Yellow
Write-Host "1. Direct call to customer service (no auth)"
Write-Host "2. Call via API Gateway (with auth)"
Write-Host "3. Call with invalid token"
Write-Host ""

# Test 1: Direct call to customer service (should be blocked by security)
Write-Host "🔍 Test 1: Direct call to customer service..." -ForegroundColor Cyan
try {
    $response = Invoke-RestMethod -Uri "$customerServiceUrl/api/customers/my-info" -Method Get -ErrorAction Stop
    Write-Host "❌ Test 1 FAILED: Should be blocked by security" -ForegroundColor Red
    Write-Host "Response: $($response | ConvertTo-Json)" -ForegroundColor Red
}
catch {
    Write-Host "✅ Test 1 PASSED: Request blocked as expected" -ForegroundColor Green
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Gray
}

Write-Host ""

# Test 2: Call via API Gateway (should also be blocked without token)
Write-Host "🔍 Test 2: Call via API Gateway without token..." -ForegroundColor Cyan
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/api/customers/my-info" -Method Get -ErrorAction Stop
    Write-Host "❌ Test 2 FAILED: Should be blocked by gateway" -ForegroundColor Red
    Write-Host "Response: $($response | ConvertTo-Json)" -ForegroundColor Red
}
catch {
    Write-Host "✅ Test 2 PASSED: Request blocked as expected" -ForegroundColor Green
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Gray
}

Write-Host ""

# Test 3: Call with invalid token
Write-Host "🔍 Test 3: Call with invalid JWT token..." -ForegroundColor Cyan
try {
    $headers = @{
        'Authorization' = 'Bearer invalid.jwt.token'
        'Content-Type'  = 'application/json'
    }
    $response = Invoke-RestMethod -Uri "$baseUrl/api/customers/my-info" -Method Get -Headers $headers -ErrorAction Stop
    Write-Host "❌ Test 3 FAILED: Should reject invalid token" -ForegroundColor Red
    Write-Host "Response: $($response | ConvertTo-Json)" -ForegroundColor Red
}
catch {
    Write-Host "✅ Test 3 PASSED: Invalid token rejected as expected" -ForegroundColor Green
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Gray
}

Write-Host ""

# Test 4: Check if customer service is running and accessible
Write-Host "🔍 Test 4: Check customer service health..." -ForegroundColor Cyan
try {
    $response = Invoke-RestMethod -Uri "$customerServiceUrl/actuator/health" -Method Get -ErrorAction Stop
    Write-Host "✅ Test 4 PASSED: Customer service is running" -ForegroundColor Green
    Write-Host "Health status: $($response.status)" -ForegroundColor Green
}
catch {
    Write-Host "❌ Test 4 FAILED: Customer service not accessible" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Test 5: Check if API Gateway is running
Write-Host "🔍 Test 5: Check API Gateway health..." -ForegroundColor Cyan
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/actuator/health" -Method Get -ErrorAction Stop
    Write-Host "✅ Test 5 PASSED: API Gateway is running" -ForegroundColor Green
    Write-Host "Health status: $($response.status)" -ForegroundColor Green
}
catch {
    Write-Host "❌ Test 5 FAILED: API Gateway not accessible" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "🏁 Test completed!" -ForegroundColor Green
Write-Host "📝 Next steps:" -ForegroundColor Yellow
Write-Host "   1. Get valid JWT token from Keycloak"
Write-Host "   2. Test /my-info with valid token"
Write-Host "   3. Create test customer data"
Write-Host ""
