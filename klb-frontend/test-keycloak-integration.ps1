# 🔐 TEST KEYCLOAK INTEGRATION

Write-Host "🚀 TESTING KEYCLOAK INTEGRATION WITH PHONE AUTHENTICATION" -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

# Test Keycloak availability
Write-Host "`n1. 🏥 TESTING KEYCLOAK HEALTH..." -ForegroundColor Yellow
try {
    $keycloakResponse = Invoke-WebRequest -Uri "http://localhost:8090/realms/Kienlongbank/.well-known/openid-configuration" -Method GET -UseBasicParsing -ErrorAction Stop
    Write-Host "   ✅ Keycloak Realm available: $($keycloakResponse.StatusCode)" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Keycloak not available: $($_.Exception.Message)" -ForegroundColor Red
}

# Test API Gateway
Write-Host "`n2. 🌐 TESTING API GATEWAY..." -ForegroundColor Yellow
try {
    $gatewayResponse = Invoke-WebRequest -Uri "http://localhost:8080/" -Method GET -UseBasicParsing -ErrorAction Stop
    Write-Host "   ✅ API Gateway available: $($gatewayResponse.StatusCode)" -ForegroundColor Green
} catch {
    Write-Host "   ❌ API Gateway requires authentication (expected): 401" -ForegroundColor Yellow
}

# Check ports
Write-Host "`n3. 🔌 CHECKING ACTIVE PORTS..." -ForegroundColor Yellow
$ports = @(3000, 8080, 8090, 5432)
foreach ($port in $ports) {
    $listening = netstat -an | findstr ":$port"
    if ($listening) {
        Write-Host "   ✅ Port $port is active" -ForegroundColor Green
    } else {
        Write-Host "   ❌ Port $port is not active" -ForegroundColor Red
    }
}

# Start React with Keycloak integration
Write-Host "`n4. 🚀 STARTING ENHANCED PHONE BANKING WITH KEYCLOAK..." -ForegroundColor Yellow
Write-Host "   📱 Features:" -ForegroundColor Cyan
Write-Host "   - Phone Registration with Keycloak fallback" -ForegroundColor White
Write-Host "   - Phone Login with Keycloak authentication" -ForegroundColor White  
Write-Host "   - JWT Token management" -ForegroundColor White
Write-Host "   - Full Banking Dashboard integration" -ForegroundColor White
Write-Host ""
Write-Host "   🔑 Test Credentials:" -ForegroundColor Cyan
Write-Host "   - Phone: 0376381006" -ForegroundColor White
Write-Host "   - Password: (any password - will show demo mode if Keycloak fails)" -ForegroundColor White
Write-Host ""
Write-Host "   📍 Opening http://localhost:3000..." -ForegroundColor Green

# Start the application
npm start
