# Script để fix user roles trong Keycloak

Write-Host "🔧 Fixing user roles in Keycloak..." -ForegroundColor Green

# Get admin token
Write-Host "🔑 Getting admin token..." -ForegroundColor Yellow
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

# Check and create roles if needed
Write-Host "🔧 Checking and creating roles..." -ForegroundColor Yellow
$roles = @("USER", "ADMIN")

foreach ($roleName in $roles) {
    try {
        # Try to get existing role
        $existingRole = Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/roles/$roleName" -Headers $headers -ErrorAction SilentlyContinue
        Write-Host "ℹ️ Role '$roleName' already exists" -ForegroundColor Blue
    } catch {
        # Create role if it doesn't exist
        $roleData = @{
            name = $roleName
            description = "Role for $roleName access"
        } | ConvertTo-Json
        
        try {
            Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/roles" -Method Post -Body $roleData -Headers $headers
            Write-Host "✅ Role '$roleName' created" -ForegroundColor Green
        } catch {
            Write-Host "❌ Failed to create role '$roleName': $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# Get testuser and assign USER role
Write-Host "👤 Getting testuser information..." -ForegroundColor Yellow
try {
    $users = Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/users?username=testuser" -Headers $headers
    
    if ($users.Count -eq 0) {
        Write-Host "❌ User 'testuser' not found!" -ForegroundColor Red
        exit 1
    }
    
    $userId = $users[0].id
    Write-Host "✅ Found testuser with ID: $userId" -ForegroundColor Green
    
    # Get current roles
    Write-Host "🔍 Checking current roles..." -ForegroundColor Yellow
    $currentRoles = Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/users/$userId/role-mappings/realm" -Headers $headers
    Write-Host "Current roles: $($currentRoles.name -join ', ')" -ForegroundColor Blue
    
    # Get USER role
    $userRole = Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/roles/USER" -Headers $headers
    
    # Check if USER role is already assigned
    $hasUserRole = $currentRoles | Where-Object { $_.name -eq "USER" }
    
    if ($hasUserRole) {
        Write-Host "ℹ️ USER role already assigned to testuser" -ForegroundColor Blue
    } else {
        # Assign USER role
        Write-Host "🔐 Assigning USER role to testuser..." -ForegroundColor Yellow
        
        # Create proper role mapping array
        $roleMapping = @(
            @{
                id = $userRole.id
                name = $userRole.name
                description = $userRole.description
                composite = $userRole.composite
                clientRole = $false
                containerId = $userRole.containerId
            }
        )
        
        $roleData = $roleMapping | ConvertTo-Json -Depth 3
        Write-Host "Role data to send: $roleData" -ForegroundColor Blue
        
        try {
            Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/users/$userId/role-mappings/realm" -Method Post -Body $roleData -Headers $headers
            Write-Host "✅ USER role assigned to testuser" -ForegroundColor Green
        } catch {
            Write-Host "❌ Failed to assign role: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host "Response details: $($_.Exception.Response.StatusCode) - $($_.Exception.Response.StatusDescription)" -ForegroundColor Red
        }
    }
    
    # Verify assignment
    Write-Host "🔍 Verifying role assignment..." -ForegroundColor Yellow
    $finalRoles = Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/users/$userId/role-mappings/realm" -Headers $headers
    Write-Host "Final roles: $($finalRoles.name -join ', ')" -ForegroundColor Green
    
} catch {
    Write-Host "❌ Error processing testuser: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Response: $($_.Exception.Response)" -ForegroundColor Red
}

Write-Host ""
Write-Host "🎉 Role assignment check complete!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Next Steps:" -ForegroundColor Cyan
Write-Host "1. Logout from the frontend application" -ForegroundColor White
Write-Host "2. Login again with testuser/password123" -ForegroundColor White
Write-Host "3. Check if USER role is now available" -ForegroundColor White
Write-Host ""
