# Script để verify Keycloak setup và debug tokens

Write-Host "🔍 Verifying Keycloak Setup..." -ForegroundColor Green

# Get admin token
$tokenBody = @{
    username = "admin"
    password = "admin"
    grant_type = "password"
    client_id = "admin-cli"
}

try {
    $tokenResponse = Invoke-RestMethod -Uri "http://localhost:8090/realms/master/protocol/openid-connect/token" -Method Post -Body $tokenBody
    $adminToken = $tokenResponse.access_token
    Write-Host "✅ Got admin token" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to get admin token: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

$headers = @{
    "Authorization" = "Bearer $adminToken"
    "Content-Type" = "application/json"
}

# Check realm roles
Write-Host "🔍 Checking realm roles..." -ForegroundColor Yellow
try {
    $realmRoles = Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/roles" -Headers $headers
    Write-Host "Realm roles found:" -ForegroundColor Green
    foreach ($role in $realmRoles) {
        Write-Host "  - $($role.name): $($role.description)" -ForegroundColor White
    }
} catch {
    Write-Host "❌ Failed to get realm roles: $($_.Exception.Message)" -ForegroundColor Red
}

# Check testuser roles
Write-Host "🔍 Checking testuser roles..." -ForegroundColor Yellow
try {
    $users = Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/users?username=testuser" -Headers $headers
    if ($users.Count -gt 0) {
        $userId = $users[0].id
        $userRoles = Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/users/$userId/role-mappings/realm" -Headers $headers
        
        Write-Host "testuser roles:" -ForegroundColor Green
        foreach ($role in $userRoles) {
            Write-Host "  - $($role.name)" -ForegroundColor White
        }
        
        if ($userRoles.Count -eq 0) {
            Write-Host "⚠️ testuser has no roles assigned!" -ForegroundColor Yellow
        }
    } else {
        Write-Host "❌ testuser not found!" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Failed to check testuser roles: $($_.Exception.Message)" -ForegroundColor Red
}

# Test getting a token for testuser
Write-Host "🔍 Testing token for testuser..." -ForegroundColor Yellow
$testTokenBody = @{
    username = "testuser"
    password = "password123"
    grant_type = "password"
    client_id = "klb-frontend"
}

try {
    $testTokenResponse = Invoke-RestMethod -Uri "http://localhost:8090/realms/Kienlongbank/protocol/openid-connect/token" -Method Post -Body $testTokenBody
    Write-Host "✅ Successfully got token for testuser" -ForegroundColor Green
    
    # Decode token (basic inspection - not full JWT decode)
    $tokenParts = $testTokenResponse.access_token.Split('.')
    if ($tokenParts.Length -eq 3) {
        try {
            # Decode JWT payload (base64url)
            $payload = $tokenParts[1]
            # Add padding if needed
            while ($payload.Length % 4 -ne 0) {
                $payload += "="
            }
            $payload = $payload.Replace('-', '+').Replace('_', '/')
            $decodedBytes = [System.Convert]::FromBase64String($payload)
            $decodedText = [System.Text.Encoding]::UTF8.GetString($decodedBytes)
            $tokenData = $decodedText | ConvertFrom-Json
            
            Write-Host "Token contains:" -ForegroundColor Green
            Write-Host "  Username: $($tokenData.preferred_username)" -ForegroundColor White
            Write-Host "  Subject: $($tokenData.sub)" -ForegroundColor White
            
            if ($tokenData.realm_access) {
                Write-Host "  Realm roles: $($tokenData.realm_access.roles -join ', ')" -ForegroundColor White
            } else {
                Write-Host "  ⚠️ No realm_access in token!" -ForegroundColor Yellow
            }
            
            if ($tokenData.resource_access) {
                Write-Host "  Resource access: $($tokenData.resource_access | ConvertTo-Json -Depth 2)" -ForegroundColor White
            } else {
                Write-Host "  ℹ️ No resource_access in token" -ForegroundColor Blue
            }
            
        } catch {
            Write-Host "❌ Failed to decode token: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
} catch {
    Write-Host "❌ Failed to get token for testuser: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "This might be because the client is not configured for password grant" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🎯 Summary:" -ForegroundColor Cyan
Write-Host "If testuser has no roles, run: powershell -ExecutionPolicy Bypass -File fix-user-roles.ps1" -ForegroundColor White
Write-Host "If roles exist but not in token, check Keycloak client configuration" -ForegroundColor White
