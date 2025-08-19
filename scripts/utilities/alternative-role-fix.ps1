# Alternative approach to assign USER role

Write-Host "🔧 Alternative USER role assignment..." -ForegroundColor Green

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
} catch {
    Write-Host "❌ Failed to get admin token" -ForegroundColor Red
    exit 1
}

$headers = @{
    "Authorization" = "Bearer $adminToken"
    "Content-Type" = "application/json"
}

# Get user and role info
$users = Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/users?username=testuser" -Headers $headers
$userId = $users[0].id

# Method 1: Try with just the essential fields
Write-Host "🔐 Method 1: Minimal role object..." -ForegroundColor Yellow
try {
    $minimalRole = @(
        @{
            id = "434a64e7-3f87-438e-ba70-78a64dc86eb8"
            name = "USER"
        }
    ) | ConvertTo-Json -Depth 2 -Compress
    
    Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/users/$userId/role-mappings/realm" -Method Post -Body $minimalRole -Headers $headers
    Write-Host "✅ Method 1 successful!" -ForegroundColor Green
} catch {
    Write-Host "❌ Method 1 failed: $($_.Exception.Message)" -ForegroundColor Red
    
    # Method 2: Try deleting existing roles first, then adding
    Write-Host "🔐 Method 2: Reset and assign..." -ForegroundColor Yellow
    try {
        # Get current roles
        $currentRoles = Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/users/$userId/role-mappings/realm" -Headers $headers
        
        # Remove default role if it exists
        $defaultRole = $currentRoles | Where-Object { $_.name -eq "default-roles-kienlongbank" }
        if ($defaultRole) {
            $removeRoleJson = @($defaultRole) | ConvertTo-Json -Depth 3
            try {
                Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/users/$userId/role-mappings/realm" -Method Delete -Body $removeRoleJson -Headers $headers
                Write-Host "✅ Removed default role" -ForegroundColor Green
            } catch {
                Write-Host "⚠️ Could not remove default role" -ForegroundColor Yellow
            }
        }
        
        # Now try to add USER role
        $userRoleJson = @(
            @{
                id = "434a64e7-3f87-438e-ba70-78a64dc86eb8"
                name = "USER"
            }
        ) | ConvertTo-Json -Depth 2
        
        Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/users/$userId/role-mappings/realm" -Method Post -Body $userRoleJson -Headers $headers
        Write-Host "✅ Method 2 successful!" -ForegroundColor Green
        
    } catch {
        Write-Host "❌ Method 2 failed: $($_.Exception.Message)" -ForegroundColor Red
        
        # Method 3: Manual user update
        Write-Host "🔐 Method 3: Update user directly..." -ForegroundColor Yellow
        try {
            # Get current user data
            $user = Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/users/$userId" -Headers $headers
            
            # Update user with attributes
            $user.attributes = @{
                "user-role" = @("USER")
            }
            
            $userUpdateJson = $user | ConvertTo-Json -Depth 5
            Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/users/$userId" -Method Put -Body $userUpdateJson -Headers $headers
            
            # Then try role assignment again
            $roleJson = @(
                @{
                    id = "434a64e7-3f87-438e-ba70-78a64dc86eb8"
                    name = "USER"
                }
            ) | ConvertTo-Json -Depth 2
            
            Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/users/$userId/role-mappings/realm" -Method Post -Body $roleJson -Headers $headers
            Write-Host "✅ Method 3 successful!" -ForegroundColor Green
            
        } catch {
            Write-Host "❌ Method 3 failed: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# Final verification
Write-Host ""
Write-Host "🔍 Final verification..." -ForegroundColor Yellow
$finalRoles = Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/users/$userId/role-mappings/realm" -Headers $headers
Write-Host "📋 Current roles:" -ForegroundColor Cyan
foreach ($role in $finalRoles) {
    $status = if ($role.name -eq "USER") { "✅" } else { "ℹ️" }
    Write-Host "   $status $($role.name)" -ForegroundColor White
}
