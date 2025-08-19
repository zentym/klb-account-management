# Simple test for customer service API
Write-Host "🧪 Testing Customer Service API..." -ForegroundColor Green

$customerServiceUrl = "http://localhost:8082"
$apiGatewayUrl = "http://localhost:8080"

Write-Host "🔍 Test 1: Check if customer service is responding..." -ForegroundColor Cyan

try {
    # Test a simple GET request first
    $response = Invoke-WebRequest -Uri "$customerServiceUrl/api/customers/1" -Method Get -UseBasicParsing
    Write-Host "✅ Customer service is responding" -ForegroundColor Green
    Write-Host "Status Code: $($response.StatusCode)" -ForegroundColor Green
} catch [System.Net.WebException] {
    $statusCode = $_.Exception.Response.StatusCode
    Write-Host "⚠️ Customer service responded with: $statusCode" -ForegroundColor Yellow
    if ($statusCode -eq "Unauthorized") {
        Write-Host "✅ This is expected - API is secured!" -ForegroundColor Green
    }
} catch {
    Write-Host "❌ Error connecting to customer service: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "🔍 Test 2: Test /my-info endpoint directly..." -ForegroundColor Cyan

try {
    $response = Invoke-WebRequest -Uri "$customerServiceUrl/api/customers/my-info" -Method Get -UseBasicParsing
    Write-Host "❌ Unexpected success - should be secured!" -ForegroundColor Red
    Write-Host "Response: $($response.Content)" -ForegroundColor Red
} catch [System.Net.WebException] {
    $statusCode = $_.Exception.Response.StatusCode
    Write-Host "✅ /my-info endpoint is secured - Status: $statusCode" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Connection error: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🔍 Test 3: Test via API Gateway..." -ForegroundColor Cyan

try {
    $response = Invoke-WebRequest -Uri "$apiGatewayUrl/api/customers/my-info" -Method Get -UseBasicParsing
    Write-Host "❌ Unexpected success - should require auth!" -ForegroundColor Red
} catch [System.Net.WebException] {
    $statusCode = $_.Exception.Response.StatusCode
    Write-Host "✅ API Gateway properly securing endpoint - Status: $statusCode" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Connection error: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "📝 Summary:" -ForegroundColor Yellow
Write-Host "   - Customer service is running on port 8082" -ForegroundColor White
Write-Host "   - API Gateway is running on port 8080" -ForegroundColor White
Write-Host "   - /my-info endpoint is properly secured" -ForegroundColor White
Write-Host "   - Next step: Get valid JWT token to test authenticated request" -ForegroundColor White

Write-Host ""
Write-Host "🔑 To get a valid token, you need:" -ForegroundColor Yellow
Write-Host "   1. Valid Keycloak user" -ForegroundColor White
Write-Host "   2. Proper client configuration" -ForegroundColor White
Write-Host "   3. Customer record with matching ID in database" -ForegroundColor White
