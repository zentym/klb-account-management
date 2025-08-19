# 🔍 DEBUG KEYCLOAK CONNECTION

Write-Host "🔍 DEBUGGING KEYCLOAK INTEGRATION" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan

# Check Keycloak availability
Write-Host "`n1. 🏥 KEYCLOAK HEALTH CHECK..." -ForegroundColor Yellow

# Check if port 8090 is listening
$keycloakPort = netstat -an | findstr ":8090"
if ($keycloakPort) {
    Write-Host "   ✅ Port 8090 is active" -ForegroundColor Green
} else {
    Write-Host "   ❌ Port 8090 is not active" -ForegroundColor Red
    Write-Host "   🔧 Start Keycloak: cd kienlongbank-project && docker-compose up -d keycloak" -ForegroundColor Yellow
    exit 1
}

# Test Keycloak realm
Write-Host "`n2. 🌐 TESTING KEYCLOAK REALM..." -ForegroundColor Yellow
try {
    $realmResponse = Invoke-WebRequest -Uri "http://localhost:8090/realms/Kienlongbank/.well-known/openid-configuration" -Method GET -UseBasicParsing -ErrorAction Stop
    Write-Host "   ✅ Kienlongbank realm available: $($realmResponse.StatusCode)" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Kienlongbank realm not available: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "   🔧 Check realm name or wait for Keycloak startup" -ForegroundColor Yellow
}

# Test master realm (for admin API)
Write-Host "`n3. 🔑 TESTING MASTER REALM..." -ForegroundColor Yellow
try {
    $masterResponse = Invoke-WebRequest -Uri "http://localhost:8090/realms/master/.well-known/openid-configuration" -Method GET -UseBasicParsing -ErrorAction Stop
    Write-Host "   ✅ Master realm available: $($masterResponse.StatusCode)" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Master realm not available: $($_.Exception.Message)" -ForegroundColor Red
}

# Test admin authentication
Write-Host "`n4. 🔐 TESTING ADMIN AUTHENTICATION..." -ForegroundColor Yellow
try {
    $body = @{
        grant_type = 'password'
        client_id = 'admin-cli'
        username = 'admin'
        password = 'admin'
    }
    
    $adminResponse = Invoke-RestMethod -Uri "http://localhost:8090/realms/master/protocol/openid-connect/token" -Method POST -Body $body -ContentType "application/x-www-form-urlencoded" -ErrorAction Stop
    
    if ($adminResponse.access_token) {
        Write-Host "   ✅ Admin authentication successful" -ForegroundColor Green
        Write-Host "   🔑 Token type: $($adminResponse.token_type)" -ForegroundColor White
        Write-Host "   ⏰ Expires in: $($adminResponse.expires_in) seconds" -ForegroundColor White
        
        # Test admin API access
        Write-Host "`n5. 🛠️ TESTING ADMIN API ACCESS..." -ForegroundColor Yellow
        try {
            $headers = @{ "Authorization" = "Bearer $($adminResponse.access_token)" }
            $usersResponse = Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/users?max=1" -Method GET -Headers $headers -ErrorAction Stop
            Write-Host "   ✅ Admin API access successful" -ForegroundColor Green
            Write-Host "   👥 Can access Kienlongbank users" -ForegroundColor White
        } catch {
            Write-Host "   ❌ Admin API access failed: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host "   🔧 Check realm name or admin permissions" -ForegroundColor Yellow
        }
        
    } else {
        Write-Host "   ❌ No access token received" -ForegroundColor Red
    }
    
} catch {
    Write-Host "   ❌ Admin authentication failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "   🔧 Check admin credentials (admin/admin)" -ForegroundColor Yellow
}

# Test client configuration
Write-Host "`n6. 📱 TESTING CLIENT CONFIGURATION..." -ForegroundColor Yellow
try {
    $body = @{
        grant_type = 'password'
        client_id = 'klb-frontend'
        username = 'testuser'  # This will fail but shows client exists
        password = 'testpass'
    }
    
    $clientResponse = Invoke-RestMethod -Uri "http://localhost:8090/realms/Kienlongbank/protocol/openid-connect/token" -Method POST -Body $body -ContentType "application/x-www-form-urlencoded" -ErrorAction Stop
    Write-Host "   ✅ Client klb-frontend exists and accepts password grant" -ForegroundColor Green
    
} catch {
    if ($_.Exception.Response.StatusCode -eq 401) {
        Write-Host "   ✅ Client klb-frontend exists (invalid credentials expected)" -ForegroundColor Green
    } else {
        Write-Host "   ❌ Client configuration issue: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "   🔧 Check client 'klb-frontend' exists with Direct Access Grant enabled" -ForegroundColor Yellow
    }
}

Write-Host "`n🎯 SUMMARY:" -ForegroundColor Yellow
Write-Host "   If all tests above are ✅, registration should work" -ForegroundColor Green
Write-Host "   If any tests fail ❌, fix those issues first" -ForegroundColor Red

Write-Host "`n🚀 Ready to test registration? Press Enter to start frontend..." -ForegroundColor Cyan
Read-Host

# Start frontend
npm start
