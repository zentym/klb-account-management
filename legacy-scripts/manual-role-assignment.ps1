#!/usr/bin/env pwsh
# Script để manually assign ADMIN role cho testuser với proper format

Write-Host "🔧 Manual Role Assignment Fixer" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

# Lấy admin token
Write-Host "`n🔑 Getting admin access token..." -ForegroundColor Yellow

$tokenBody = @{
    "username" = "admin"
    "password" = "admin"
    "grant_type" = "password"
    "client_id" = "admin-cli"
}

try {
    $tokenResponse = Invoke-RestMethod -Uri "http://localhost:8090/realms/master/protocol/openid-connect/token" -Method Post -Body $tokenBody
    $adminToken = $tokenResponse.access_token
    Write-Host "✅ Admin token obtained!" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to get admin token: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

$headers = @{
    "Authorization" = "Bearer $adminToken"
    "Content-Type" = "application/json"
}

# Lấy user ID
Write-Host "`n🔍 Finding testuser..." -ForegroundColor Yellow
try {
    $users = Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/users?username=testuser" -Method Get -Headers $headers
    $userId = $users[0].id
    Write-Host "✅ Found testuser (ID: $userId)" -ForegroundColor Green
} catch {
    Write-Host "❌ Error finding user: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Lấy ADMIN role
Write-Host "`n👑 Getting ADMIN role..." -ForegroundColor Yellow
try {
    $adminRole = Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/roles/ADMIN" -Method Get -Headers $headers
    Write-Host "✅ Found ADMIN role (ID: $($adminRole.id))" -ForegroundColor Green
} catch {
    Write-Host "❌ ADMIN role not found: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Manual role assignment với correct format
Write-Host "`n🎯 Assigning ADMIN role to testuser..." -ForegroundColor Yellow

# Format phải đúng như Keycloak API expects
$roleData = @(
    @{
        "id" = $adminRole.id
        "name" = $adminRole.name
        "composite" = $false
        "clientRole" = $false
        "containerId" = "Kienlongbank"
    }
)

$roleJson = $roleData | ConvertTo-Json -Depth 3

Write-Host "   📝 Role assignment payload:" -ForegroundColor Blue
Write-Host "   $roleJson" -ForegroundColor Gray

try {
    $response = Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/users/$userId/role-mappings/realm" -Method Post -Body $roleJson -Headers $headers
    Write-Host "✅ ADMIN role successfully assigned to testuser!" -ForegroundColor Green
} catch {
    Write-Host "❌ Error assigning role: $($_.Exception.Message)" -ForegroundColor Red
    
    # Try to get more detailed error info
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $errorContent = $reader.ReadToEnd()
        Write-Host "   📝 Error details: $errorContent" -ForegroundColor Yellow
    }
}

# Verify role assignment
Write-Host "`n🔍 Verifying role assignment..." -ForegroundColor Yellow
try {
    $userRoles = Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/users/$userId/role-mappings/realm" -Method Get -Headers $headers
    
    Write-Host "   📋 Current user roles:" -ForegroundColor Blue
    $userRoles | ForEach-Object {
        Write-Host "      - $($_.name): $($_.description)" -ForegroundColor White
    }
    
    $hasAdminRole = $userRoles | Where-Object { $_.name -eq "ADMIN" }
    if ($hasAdminRole) {
        Write-Host "✅ User now has ADMIN role!" -ForegroundColor Green
    } else {
        Write-Host "❌ User still doesn't have ADMIN role" -ForegroundColor Red
    }
    
} catch {
    Write-Host "❌ Error verifying roles: $($_.Exception.Message)" -ForegroundColor Red
}

# Test new token
Write-Host "`n🧪 Testing new JWT token..." -ForegroundColor Yellow

$loginData = @{
    "username" = "testuser"
    "password" = "password123"
    "grant_type" = "password"
    "client_id" = "klb-frontend"
} 

try {
    $loginResponse = Invoke-RestMethod -Uri "http://localhost:8090/realms/Kienlongbank/protocol/openid-connect/token" -Method Post -Body $loginData -ContentType "application/x-www-form-urlencoded"
    
    $accessToken = $loginResponse.access_token
    Write-Host "✅ Login successful!" -ForegroundColor Green
    
    # Decode token để kiểm tra roles
    $parts = $accessToken.Split('.')
    $payload = $parts[1]
    while ($payload.Length % 4) { $payload += "=" }
    $decodedBytes = [System.Convert]::FromBase64String($payload)
    $decodedJson = [System.Text.Encoding]::UTF8.GetString($decodedBytes)
    $decodedToken = $decodedJson | ConvertFrom-Json
    
    Write-Host "   📋 Token roles:" -ForegroundColor Blue
    if ($decodedToken.realm_access -and $decodedToken.realm_access.roles) {
        $decodedToken.realm_access.roles | ForEach-Object {
            Write-Host "      - $_" -ForegroundColor White
        }
        
        if ($decodedToken.realm_access.roles -contains "ADMIN") {
            Write-Host "✅ JWT token contains ADMIN role!" -ForegroundColor Green
        } else {
            Write-Host "❌ JWT token does NOT contain ADMIN role" -ForegroundColor Red
        }
    } else {
        Write-Host "   ⚠️ No realm_access.roles in token" -ForegroundColor Yellow
    }
    
    # Test admin API
    Write-Host "`n🔐 Testing admin API access..." -ForegroundColor Yellow
    $authHeaders = @{
        "Authorization" = "Bearer $accessToken"
        "Content-Type" = "application/json"
    }
    
    try {
        $adminResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/admin/hello" -Method Get -Headers $authHeaders
        Write-Host "✅ Admin API access: SUCCESS!" -ForegroundColor Green
        Write-Host "   📝 Response: $adminResponse" -ForegroundColor White
    } catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        Write-Host "❌ Admin API access: FAILED (Status: $statusCode)" -ForegroundColor Red
    }
    
} catch {
    Write-Host "❌ Login test failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n🏁 Manual assignment completed!" -ForegroundColor Green
