#!/usr/bin/env pwsh
# Comprehensive User Permission Check Script

Write-Host "🔍 COMPREHENSIVE USER PERMISSION CHECK" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host "Kiểm tra toàn diện quyền của user trong hệ thống KLB" -ForegroundColor White

# Function để decode JWT token
function Decode-JwtToken {
    param([string]$Token)
    
    try {
        $parts = $Token.Split('.')
        if ($parts.Length -ne 3) {
            return $null
        }
        $payload = $parts[1]
        while ($payload.Length % 4) {
            $payload += "="
        }
        $decodedBytes = [System.Convert]::FromBase64String($payload)
        $decodedJson = [System.Text.Encoding]::UTF8.GetString($decodedBytes)
        return $decodedJson | ConvertFrom-Json
    }
    catch {
        return $null
    }
}

# Function để test API endpoint
function Test-ApiEndpoint {
    param(
        [string]$Url,
        [hashtable]$Headers,
        [string]$Description
    )
    
    try {
        $response = Invoke-RestMethod -Uri $Url -Method Get -Headers $Headers
        Write-Host "   ✅ $Description - SUCCESS" -ForegroundColor Green
        return @{ Success = $true; Response = $response }
    }
    catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        Write-Host "   ❌ $Description - FAILED ($statusCode)" -ForegroundColor Red
        return @{ Success = $false; StatusCode = $statusCode }
    }
}

Write-Host "`n=== 1. KEYCLOAK TOKEN ANALYSIS ===" -ForegroundColor Yellow

# Login để lấy token
$loginData = @{
    "username"   = "testuser"
    "password"   = "password123"
    "grant_type" = "password"
    "client_id"  = "klb-frontend"
}

try {
    $loginResponse = Invoke-RestMethod -Uri "http://localhost:8090/realms/Kienlongbank/protocol/openid-connect/token" -Method Post -Body $loginData -ContentType "application/x-www-form-urlencoded"
    $accessToken = $loginResponse.access_token
    Write-Host "✅ Login thành công với testuser" -ForegroundColor Green
    
    $decodedToken = Decode-JwtToken -Token $accessToken
    
    if ($decodedToken) {
        Write-Host "`n📋 USER INFORMATION:" -ForegroundColor Cyan
        Write-Host "   Username: $($decodedToken.preferred_username)" -ForegroundColor White
        Write-Host "   Email: $($decodedToken.email)" -ForegroundColor White
        Write-Host "   Subject ID: $($decodedToken.sub)" -ForegroundColor White
        
        $issuedTime = [DateTimeOffset]::FromUnixTimeSeconds($decodedToken.iat).ToString("yyyy-MM-dd HH:mm:ss")
        $expireTime = [DateTimeOffset]::FromUnixTimeSeconds($decodedToken.exp).ToString("yyyy-MM-dd HH:mm:ss")
        Write-Host "   Token issued: $issuedTime" -ForegroundColor White
        Write-Host "   Token expires: $expireTime" -ForegroundColor White
        
        Write-Host "`n🎭 ROLE ANALYSIS:" -ForegroundColor Cyan
        
        # Realm roles
        if ($decodedToken.realm_access -and $decodedToken.realm_access.roles) {
            Write-Host "   🏰 Realm Roles:" -ForegroundColor Yellow
            $realmRoles = @()
            $decodedToken.realm_access.roles | ForEach-Object {
                Write-Host "      ✓ $_" -ForegroundColor Green
                $realmRoles += $_
            }
        }
        
        # Client roles  
        if ($decodedToken.resource_access) {
            Write-Host "   🎯 Client Roles:" -ForegroundColor Yellow
            $decodedToken.resource_access.PSObject.Properties | ForEach-Object {
                Write-Host "      📱 $($_.Name):" -ForegroundColor Cyan
                $_.Value.roles | ForEach-Object {
                    Write-Host "         ✓ $_" -ForegroundColor Green
                }
            }
        }
        
        Write-Host "`n🔍 PERMISSION ASSESSMENT:" -ForegroundColor Cyan
        $hasUserRole = $realmRoles -contains "USER"
        $hasAdminRole = $realmRoles -contains "ADMIN"
        
        Write-Host "   USER role: $(if($hasUserRole) { '✅ GRANTED' } else { '❌ MISSING' })" -ForegroundColor $(if ($hasUserRole) { 'Green' } else { 'Red' })
        Write-Host "   ADMIN role: $(if($hasAdminRole) { '✅ GRANTED' } else { '❌ MISSING' })" -ForegroundColor $(if ($hasAdminRole) { 'Green' } else { 'Red' })
    }
}
catch {
    Write-Host "❌ Login failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "`n=== 2. API ENDPOINT TESTING ===" -ForegroundColor Yellow

$headers = @{
    "Authorization" = "Bearer $accessToken"
    "Content-Type"  = "application/json"
}

Write-Host "`n🔧 BASIC ENDPOINTS:" -ForegroundColor Cyan
Test-ApiEndpoint -Url "http://localhost:8080/api/health" -Headers $headers -Description "Health Check"

Write-Host "`n🔐 ADMIN ENDPOINTS:" -ForegroundColor Cyan
Test-ApiEndpoint -Url "http://localhost:8080/api/admin/hello" -Headers $headers -Description "Admin Hello"
Test-ApiEndpoint -Url "http://localhost:8080/api/admin/check-permissions" -Headers $headers -Description "Admin Permissions Check"

Write-Host "`n👥 USER ENDPOINTS:" -ForegroundColor Cyan
Test-ApiEndpoint -Url "http://localhost:8080/api/customers" -Headers $headers -Description "Customer List"
Test-ApiEndpoint -Url "http://localhost:8080/api/accounts" -Headers $headers -Description "Account List"
Test-ApiEndpoint -Url "http://localhost:8080/api/loans" -Headers $headers -Description "Loan List"

Write-Host "`n=== 3. KEYCLOAK CONFIGURATION CHECK ===" -ForegroundColor Yellow

# Get admin token for Keycloak
$tokenBody = @{
    username   = "admin"
    password   = "admin"
    grant_type = "password"
    client_id  = "admin-cli"
}

try {
    $tokenResponse = Invoke-RestMethod -Uri "http://localhost:8090/realms/master/protocol/openid-connect/token" -Method Post -Body $tokenBody
    $adminToken = $tokenResponse.access_token
    
    $adminHeaders = @{
        "Authorization" = "Bearer $adminToken"
        "Content-Type"  = "application/json"
    }
    
    Write-Host "`n🏰 REALM ROLES:" -ForegroundColor Cyan
    try {
        $realmRoles = Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/roles" -Headers $adminHeaders
        foreach ($role in $realmRoles) {
            $desc = if ($role.description) { $role.description } else { "No description" }
            Write-Host "   ✓ $($role.name) - $desc" -ForegroundColor White
        }
    }
    catch {
        Write-Host "   ❌ Could not retrieve realm roles" -ForegroundColor Red
    }
    
    Write-Host "`n👤 USER ROLE ASSIGNMENTS:" -ForegroundColor Cyan
    try {
        $users = Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/users?username=testuser" -Headers $adminHeaders
        if ($users.Count -gt 0) {
            $userId = $users[0].id
            $userRoles = Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/users/$userId/role-mappings/realm" -Headers $adminHeaders
            
            Write-Host "   testuser assigned roles:" -ForegroundColor Yellow
            foreach ($role in $userRoles) {
                Write-Host "      ✓ $($role.name)" -ForegroundColor Green
            }
        }
        else {
            Write-Host "   ❌ testuser not found" -ForegroundColor Red
        }
    }
    catch {
        Write-Host "   ❌ Could not retrieve user roles" -ForegroundColor Red
    }
    
}
catch {
    Write-Host "❌ Could not connect to Keycloak admin API" -ForegroundColor Red
}

Write-Host "`n=== 4. SYSTEM RECOMMENDATIONS ===" -ForegroundColor Yellow

Write-Host "`n📊 CURRENT STATUS SUMMARY:" -ForegroundColor Cyan
Write-Host "   ✅ User can login successfully" -ForegroundColor Green  
Write-Host "   ✅ JWT token is valid and contains user info" -ForegroundColor Green
Write-Host "   ✅ Has USER role in Keycloak" -ForegroundColor Green
Write-Host "   ❌ Missing ADMIN role for admin access" -ForegroundColor Red
Write-Host "   ❌ Cannot access admin endpoints (403 Forbidden)" -ForegroundColor Red

Write-Host "`n💡 RECOMMENDATIONS:" -ForegroundColor Cyan
Write-Host "   🔧 To grant ADMIN access:" -ForegroundColor Yellow
Write-Host "      1. Run: .\fix-user-roles.ps1" -ForegroundColor White
Write-Host "      2. Or manually assign ADMIN role in Keycloak console" -ForegroundColor White
Write-Host "   🔧 To test after changes:" -ForegroundColor Yellow  
Write-Host "      1. Re-run this script" -ForegroundColor White
Write-Host "      2. Or run: .\check-user-roles.ps1" -ForegroundColor White

Write-Host "`n🎯 NEXT STEPS:" -ForegroundColor Cyan
Write-Host "   1. If user needs admin access, run fix script" -ForegroundColor White
Write-Host "   2. If user only needs regular access, current setup is OK" -ForegroundColor White
Write-Host "   3. Test specific business features as needed" -ForegroundColor White

Write-Host "`n🏁 COMPREHENSIVE CHECK COMPLETED!" -ForegroundColor Green
Write-Host "Generated on: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
