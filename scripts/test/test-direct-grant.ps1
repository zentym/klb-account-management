# Test Keycloak Direct Grant Configuration

Write-Host "🧪 Testing Keycloak Direct Grant..." -ForegroundColor Blue

# Test if Keycloak is running
try {
    $healthCheck = Invoke-RestMethod -Uri "http://localhost:8090/realms/Kienlongbank/.well-known/openid_configuration" -Method Get
    Write-Host "✅ Keycloak is running and realm 'Kienlongbank' exists" -ForegroundColor Green
} catch {
    Write-Host "❌ Keycloak is not accessible. Make sure it's running on port 8090" -ForegroundColor Red
    Write-Host "   Run: docker-compose up -d keycloak" -ForegroundColor Yellow
    exit 1
}

# Test direct grant with existing user
Write-Host "🔍 Testing direct grant with admin user..." -ForegroundColor Blue

$testLoginData = @{
    "username" = "admin"
    "password" = "admin123"
    "grant_type" = "password"
    "client_id" = "klb-frontend"
}

try {
    $testResponse = Invoke-RestMethod -Uri "http://localhost:8090/realms/Kienlongbank/protocol/openid-connect/token" -Method Post -Body $testLoginData -ContentType "application/x-www-form-urlencoded"
    Write-Host "✅ Direct grant working!" -ForegroundColor Green
    Write-Host "   Token type: $($testResponse.token_type)" -ForegroundColor White
    Write-Host "   Expires in: $($testResponse.expires_in) seconds" -ForegroundColor White
    
    # Decode token to show user info
    $tokenParts = $testResponse.access_token.Split('.')
    if ($tokenParts.Length -eq 3) {
        # Decode payload (base64url decode is complex in PowerShell, so just show token exists)
        Write-Host "   Access token received ($(($testResponse.access_token).Length) chars)" -ForegroundColor White
    }
    
} catch {
    Write-Host "❌ Direct grant failed!" -ForegroundColor Red
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Yellow
    
    # Check if it's a client configuration issue
    if ($_.Exception.Message -like "*invalid_client*") {
        Write-Host "   Issue: Client 'klb-frontend' may not be configured for direct grants" -ForegroundColor Yellow
        Write-Host "   Solution: Enable 'Direct Access Grants' in Keycloak admin console" -ForegroundColor Yellow
    } elseif ($_.Exception.Message -like "*invalid_grant*") {
        Write-Host "   Issue: User credentials may be incorrect" -ForegroundColor Yellow
        Write-Host "   Solution: Check if user 'admin' exists with password 'admin123'" -ForegroundColor Yellow
    }
    exit 1
}

# Test with second user
Write-Host "🔍 Testing with testuser..." -ForegroundColor Blue

$testUser2Data = @{
    "username" = "testuser"
    "password" = "password123"
    "grant_type" = "password"
    "client_id" = "klb-frontend"
}

try {
    $testUser2Response = Invoke-RestMethod -Uri "http://localhost:8090/realms/Kienlongbank/protocol/openid-connect/token" -Method Post -Body $testUser2Data -ContentType "application/x-www-form-urlencoded"
    Write-Host "✅ testuser login working!" -ForegroundColor Green
} catch {
    Write-Host "⚠️  testuser login failed (this might be expected if user doesn't exist yet)" -ForegroundColor Yellow
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Gray
}

Write-Host ""
Write-Host "✅ Keycloak Direct Grant Testing Completed!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Status Summary:" -ForegroundColor Yellow
Write-Host "   ✅ Keycloak is accessible" -ForegroundColor White
Write-Host "   ✅ Direct grant flow is working for admin user" -ForegroundColor White
Write-Host "   📱 Ready for custom login UI!" -ForegroundColor White
Write-Host ""
Write-Host "🚀 Next Steps:" -ForegroundColor Cyan
Write-Host "   1. Start the frontend: cd klb-frontend && npm start" -ForegroundColor White
Write-Host "   2. Navigate to: http://localhost:3000/custom-login" -ForegroundColor White
Write-Host "   3. Test login with: admin/admin123" -ForegroundColor White
