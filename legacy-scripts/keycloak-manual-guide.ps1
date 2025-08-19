#!/usr/bin/env pwsh
# Alternative approach - Direct Keycloak Admin Console approach

Write-Host "🔧 Alternative Keycloak Role Configuration" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan

Write-Host "`n🎯 Manual Steps to Fix Role Issues:" -ForegroundColor Yellow
Write-Host "====================================" -ForegroundColor Yellow

Write-Host "`n1. 🌐 Open Keycloak Admin Console:" -ForegroundColor Green
Write-Host "   URL: http://localhost:8090" -ForegroundColor White
Write-Host "   Username: admin" -ForegroundColor White
Write-Host "   Password: admin" -ForegroundColor White

Write-Host "`n2. 📁 Navigate to Kienlongbank Realm:" -ForegroundColor Green
Write-Host "   - Click dropdown menu (currently 'Master')" -ForegroundColor White
Write-Host "   - Select 'Kienlongbank' realm" -ForegroundColor White

Write-Host "`n3. 👑 Create Roles (if not already exist):" -ForegroundColor Green
Write-Host "   - Go to Realm settings > Roles" -ForegroundColor White
Write-Host "   - Click 'Add Role'" -ForegroundColor White
Write-Host "   - Role Name: ADMIN" -ForegroundColor White
Write-Host "   - Description: Administrator role for full system access" -ForegroundColor White
Write-Host "   - Save" -ForegroundColor White
Write-Host "   - Repeat for USER role" -ForegroundColor White

Write-Host "`n4. 👤 Assign Role to User:" -ForegroundColor Green
Write-Host "   - Go to Users > View all users" -ForegroundColor White
Write-Host "   - Click on 'testuser'" -ForegroundColor White
Write-Host "   - Go to 'Role Mappings' tab" -ForegroundColor White
Write-Host "   - In 'Available Roles', find 'ADMIN'" -ForegroundColor White
Write-Host "   - Select 'ADMIN' and click 'Add selected'" -ForegroundColor White

Write-Host "`n5. 🔧 Configure Client Mappers:" -ForegroundColor Green
Write-Host "   - Go to Clients > klb-frontend" -ForegroundColor White
Write-Host "   - Go to 'Mappers' tab" -ForegroundColor White
Write-Host "   - Click 'Add Builtin'" -ForegroundColor White
Write-Host "   - Select 'realm roles' and add it" -ForegroundColor White
Write-Host "   - OR create custom mapper:" -ForegroundColor White
Write-Host "     * Name: realm-roles" -ForegroundColor White
Write-Host "     * Mapper Type: User Realm Role" -ForegroundColor White
Write-Host "     * Token Claim Name: realm_access.roles" -ForegroundColor White
Write-Host "     * Claim JSON Type: String" -ForegroundColor White
Write-Host "     * Multivalued: ON" -ForegroundColor White
Write-Host "     * Add to access token: ON" -ForegroundColor White

Write-Host "`n🔄 Let me try programmatic approach one more time..." -ForegroundColor Yellow

# Lấy admin token
$tokenBody = @{
    "username" = "admin"
    "password" = "admin"
    "grant_type" = "password"
    "client_id" = "admin-cli"
}

try {
    $tokenResponse = Invoke-RestMethod -Uri "http://localhost:8090/realms/master/protocol/openid-connect/token" -Method Post -Body $tokenBody
    $adminToken = $tokenResponse.access_token
    
    $headers = @{
        "Authorization" = "Bearer $adminToken"
        "Content-Type" = "application/json"
    }
    
    # Check current user roles
    Write-Host "`n🔍 Current user role mappings:" -ForegroundColor Blue
    
    $users = Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/users?username=testuser" -Method Get -Headers $headers
    $userId = $users[0].id
    
    $currentRoles = Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/users/$userId/role-mappings" -Method Get -Headers $headers
    
    Write-Host "   Realm roles:" -ForegroundColor Yellow
    if ($currentRoles.realmMappings) {
        $currentRoles.realmMappings | ForEach-Object {
            Write-Host "      - $($_.name)" -ForegroundColor White
        }
    } else {
        Write-Host "      (none)" -ForegroundColor Gray
    }
    
    # Try different role assignment approach
    Write-Host "`n🎯 Trying alternative role assignment method..." -ForegroundColor Yellow
    
    # Get available roles for assignment
    $availableRoles = Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/users/$userId/role-mappings/realm/available" -Method Get -Headers $headers
    
    Write-Host "   Available roles for assignment:" -ForegroundColor Blue
    $availableRoles | ForEach-Object {
        Write-Host "      - $($_.name) (ID: $($_.id))" -ForegroundColor White
    }
    
    # Find ADMIN role in available roles
    $adminRole = $availableRoles | Where-Object { $_.name -eq "ADMIN" }
    
    if ($adminRole) {
        Write-Host "`n   ✅ Found ADMIN role in available roles" -ForegroundColor Green
        
        # Try simplified assignment
        $roleAssignment = @($adminRole) | ConvertTo-Json -Depth 2
        
        Write-Host "   📝 Attempting assignment with payload:" -ForegroundColor Blue
        Write-Host "   $roleAssignment" -ForegroundColor Gray
        
        try {
            Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/users/$userId/role-mappings/realm" -Method Post -Body $roleAssignment -Headers $headers
            Write-Host "   ✅ Role assignment SUCCESSFUL!" -ForegroundColor Green
        } catch {
            Write-Host "   ❌ Role assignment still failed" -ForegroundColor Red
            
            # Last resort - try individual properties
            $simpleRole = @{
                "id" = $adminRole.id
                "name" = $adminRole.name
            } | ConvertTo-Json
            
            Write-Host "   🔄 Trying minimal payload:" -ForegroundColor Yellow
            Write-Host "   $simpleRole" -ForegroundColor Gray
            
            try {
                Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/users/$userId/role-mappings/realm" -Method Post -Body "[$simpleRole]" -Headers $headers
                Write-Host "   ✅ Minimal payload worked!" -ForegroundColor Green
            } catch {
                Write-Host "   ❌ All programmatic attempts failed" -ForegroundColor Red
                Write-Host "   🔧 Please use manual steps above" -ForegroundColor Yellow
            }
        }
    } else {
        Write-Host "   ❌ ADMIN role not found in available roles" -ForegroundColor Red
    }
    
} catch {
    Write-Host "❌ Failed to connect to Keycloak: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n🎯 Alternative Solution - Check Backend Configuration:" -ForegroundColor Cyan
Write-Host "=====================================================" -ForegroundColor Cyan

Write-Host "`nThe issue might also be in the Spring Boot configuration." -ForegroundColor Yellow
Write-Host "Let me check the JWT configuration..." -ForegroundColor Yellow

# Check if Spring Boot is expecting different role format
Write-Host "`n🔍 Current Spring Security Configuration:" -ForegroundColor Blue

# Read the security config
try {
    $securityConfigPath = "kienlongbank-project/main-app/src/main/java/com/kienlongbank/klbaccountmanagement/config/SecurityConfig.java"
    if (Test-Path $securityConfigPath) {
        $securityConfig = Get-Content $securityConfigPath -Raw
        
        Write-Host "   📝 Security config snippet:" -ForegroundColor Yellow
        $lines = $securityConfig -split "`n"
        $authSection = $lines | Where-Object { $_ -match "hasAuthority|ROLE_" }
        $authSection | ForEach-Object {
            Write-Host "      $($_.Trim())" -ForegroundColor White
        }
        
        if ($securityConfig -match "hasAuthority.*ROLE_ADMIN") {
            Write-Host "`n   ✅ Backend expects 'ROLE_ADMIN' authority" -ForegroundColor Green
            Write-Host "   💡 JWT token should contain 'ADMIN' in realm_access.roles" -ForegroundColor Blue
            Write-Host "   💡 Spring Security will automatically add 'ROLE_' prefix" -ForegroundColor Blue
        }
    }
} catch {
    Write-Host "   ⚠️ Could not read security config" -ForegroundColor Yellow
}

Write-Host "`n📋 Summary & Next Steps:" -ForegroundColor Cyan
Write-Host "========================" -ForegroundColor Cyan

Write-Host "✅ Actions completed:" -ForegroundColor Green
Write-Host "   - Created ADMIN and USER roles in Keycloak" -ForegroundColor White
Write-Host "   - Configured realm roles mapper" -ForegroundColor White

Write-Host "`n⚠️ Still need to fix:" -ForegroundColor Yellow
Write-Host "   - Assign ADMIN role to testuser (use manual steps above)" -ForegroundColor White
Write-Host "   - Verify JWT token contains roles in correct format" -ForegroundColor White

Write-Host "`n🔄 Test after manual assignment:" -ForegroundColor Blue
Write-Host "   powershell -ExecutionPolicy Bypass -File check-user-roles.ps1" -ForegroundColor White

Write-Host "`n🌐 Quick manual fix:" -ForegroundColor Green
Write-Host "   1. Open http://localhost:8090" -ForegroundColor White
Write-Host "   2. Login: admin/admin" -ForegroundColor White
Write-Host "   3. Switch to Kienlongbank realm" -ForegroundColor White
Write-Host "   4. Users > testuser > Role Mappings" -ForegroundColor White
Write-Host "   5. Add ADMIN role from Available Roles" -ForegroundColor White
