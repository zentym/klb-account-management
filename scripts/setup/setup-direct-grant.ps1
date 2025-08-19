# Configure Keycloak for Direct Grant (Custom Login UI)

Write-Host "🔧 Configuring Keycloak for Direct Grant Access..." -ForegroundColor Blue

# Get admin token
$adminLoginData = @{
    "username" = "admin"
    "password" = "admin"
    "grant_type" = "password"
    "client_id" = "admin-cli"
}

try {
    $adminResponse = Invoke-RestMethod -Uri "http://localhost:8090/realms/master/protocol/openid-connect/token" -Method Post -Body $adminLoginData -ContentType "application/x-www-form-urlencoded"
    $adminToken = $adminResponse.access_token
    Write-Host "✅ Got admin token" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to get admin token: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Update client to enable direct access grants
$headers = @{
    "Authorization" = "Bearer $adminToken"
    "Content-Type" = "application/json"
}

# Get current client configuration
try {
    $clients = Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/clients" -Method Get -Headers $headers
    $klbClient = $clients | Where-Object { $_.clientId -eq "klb-frontend" }
    
    if (-not $klbClient) {
        Write-Host "❌ klb-frontend client not found!" -ForegroundColor Red
        exit 1
    }
    
    $clientId = $klbClient.id
    Write-Host "✅ Found klb-frontend client: $clientId" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to get client: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Update client to enable direct access grants
$clientUpdate = @{
    "directAccessGrantsEnabled" = $true
    "publicClient" = $true
    "standardFlowEnabled" = $true
    "implicitFlowEnabled" = $false
    "serviceAccountsEnabled" = $false
    "redirectUris" = @("http://localhost:3000/*")
    "webOrigins" = @("http://localhost:3000")
} | ConvertTo-Json

try {
    Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/clients/$clientId" -Method Put -Body $clientUpdate -Headers $headers
    Write-Host "✅ Updated client configuration for direct access grants" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to update client: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Test direct grant flow
Write-Host "🧪 Testing direct grant flow..." -ForegroundColor Blue

$testLoginData = @{
    "username" = "admin"
    "password" = "admin123"
    "grant_type" = "password"
    "client_id" = "klb-frontend"
}

try {
    $testResponse = Invoke-RestMethod -Uri "http://localhost:8090/realms/Kienlongbank/protocol/openid-connect/token" -Method Post -Body $testLoginData -ContentType "application/x-www-form-urlencoded"
    Write-Host "✅ Direct grant flow working!" -ForegroundColor Green
    Write-Host "   Token type: $($testResponse.token_type)" -ForegroundColor White
    Write-Host "   Expires in: $($testResponse.expires_in) seconds" -ForegroundColor White
} catch {
    Write-Host "⚠️  Direct grant test failed: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "   This is normal if user doesn't exist yet" -ForegroundColor Gray
}

Write-Host "✅ Keycloak configuration completed!" -ForegroundColor Green
Write-Host "📋 Next steps:" -ForegroundColor Yellow
Write-Host "   1. Create custom login service" -ForegroundColor White
Write-Host "   2. Update LoginPage component" -ForegroundColor White
Write-Host "   3. Test with existing users" -ForegroundColor White
