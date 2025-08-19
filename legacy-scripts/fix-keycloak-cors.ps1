# PowerShell script to fix CORS issues in Keycloak

Write-Host "🔧 Fixing Keycloak CORS configuration..." -ForegroundColor Green

# Wait for Keycloak to be ready
Write-Host "⏳ Checking Keycloak availability..." -ForegroundColor Yellow
do {
    Start-Sleep -Seconds 2
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8090/realms/master/.well-known/openid-configuration" -UseBasicParsing -ErrorAction SilentlyContinue
        $ready = $response.StatusCode -eq 200
    }
    catch {
        $ready = $false
    }
} while (-not $ready)

Write-Host "✅ Keycloak is ready!" -ForegroundColor Green

# Get admin token
Write-Host "🔑 Getting admin token..." -ForegroundColor Yellow
$tokenBody = @{
    username   = "admin"
    password   = "admin"
    grant_type = "password"
    client_id  = "admin-cli"
}

try {
    $tokenResponse = Invoke-RestMethod -Uri "http://localhost:8090/realms/master/protocol/openid-connect/token" -Method Post -Body $tokenBody
    $adminToken = $tokenResponse.access_token
    Write-Host "✅ Got admin token" -ForegroundColor Green
}
catch {
    Write-Host "❌ Failed to get admin token: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

$headers = @{
    "Authorization" = "Bearer $adminToken"
    "Content-Type"  = "application/json"
}

# Get the client ID first
Write-Host "🔍 Finding klb-frontend client..." -ForegroundColor Yellow
try {
    $clients = Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/clients" -Method Get -Headers $headers
    $frontendClient = $clients | Where-Object { $_.clientId -eq "klb-frontend" }
    
    if (-not $frontendClient) {
        Write-Host "❌ klb-frontend client not found" -ForegroundColor Red
        exit 1
    }
    
    $clientUuid = $frontendClient.id
    Write-Host "✅ Found klb-frontend client: $clientUuid" -ForegroundColor Green
}
catch {
    Write-Host "❌ Failed to find client: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Update client with proper CORS settings
Write-Host "🔧 Updating client CORS settings..." -ForegroundColor Yellow
$updatedClientData = @{
    id                        = $clientUuid
    clientId                  = "klb-frontend"
    name                      = "KLB Frontend Application"
    enabled                   = $true
    publicClient              = $true
    directAccessGrantsEnabled = $true
    standardFlowEnabled       = $true
    implicitFlowEnabled       = $false
    serviceAccountsEnabled    = $false
    redirectUris              = @(
        "http://localhost:3000/*",
        "http://localhost:3000/callback",
        "http://localhost:3000/silent-callback"
    )
    webOrigins                = @(
        "http://localhost:3000",
        "http://127.0.0.1:3000"
    )
    protocol                  = "openid-connect"
    attributes                = @{
        "access.token.lifespan"       = "3600"
        "client.session.idle.timeout" = "1800"
        "client.session.max.lifespan" = "36000"
        "post.logout.redirect.uris"   = "http://localhost:3000/*"
    }
} | ConvertTo-Json -Depth 3

try {
    Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/clients/$clientUuid" -Method Put -Body $updatedClientData -Headers $headers
    Write-Host "✅ Client CORS settings updated" -ForegroundColor Green
}
catch {
    Write-Host "❌ Failed to update client: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Response: $($_.Exception.Response)" -ForegroundColor Red
}

# Test the CORS configuration
Write-Host "🧪 Testing CORS configuration..." -ForegroundColor Yellow
try {
    $corsTestHeaders = @{
        "Origin"                         = "http://localhost:3000"
        "Access-Control-Request-Method"  = "GET"
        "Access-Control-Request-Headers" = "authorization,content-type"
    }
    
    $corsResponse = Invoke-WebRequest -Uri "http://localhost:8090/realms/Kienlongbank/.well-known/openid-configuration" -Method Options -Headers $corsTestHeaders -UseBasicParsing -ErrorAction SilentlyContinue
    
    if ($corsResponse.StatusCode -eq 200 -or $corsResponse.StatusCode -eq 204) {
        Write-Host "✅ CORS preflight test passed" -ForegroundColor Green
    }
    else {
        Write-Host "⚠️ CORS preflight test failed with status: $($corsResponse.StatusCode)" -ForegroundColor Yellow
    }
}
catch {
    Write-Host "⚠️ CORS preflight test failed: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Test direct endpoint access
Write-Host "🧪 Testing direct endpoint access..." -ForegroundColor Yellow
try {
    $configResponse = Invoke-RestMethod -Uri "http://localhost:8090/realms/Kienlongbank/.well-known/openid-configuration" -Method Get
    Write-Host "✅ Keycloak configuration endpoint is accessible" -ForegroundColor Green
    Write-Host "   Issuer: $($configResponse.issuer)" -ForegroundColor White
    Write-Host "   Authorization endpoint: $($configResponse.authorization_endpoint)" -ForegroundColor White
}
catch {
    Write-Host "❌ Failed to access configuration endpoint: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "🎉 CORS configuration fix complete!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Updated Configuration:" -ForegroundColor Cyan
Write-Host "   Redirect URIs: http://localhost:3000/*, http://localhost:3000/callback" -ForegroundColor White
Write-Host "   Web Origins: http://localhost:3000, http://127.0.0.1:3000" -ForegroundColor White
Write-Host "   Public Client: Yes" -ForegroundColor White
Write-Host ""
Write-Host "🚀 Try the frontend login again!" -ForegroundColor Green
Write-Host "   Frontend URL: http://localhost:3000" -ForegroundColor White
Write-Host "   Test User: testuser / password123" -ForegroundColor White
