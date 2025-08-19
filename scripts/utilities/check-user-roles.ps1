# Script to check user roles in Keycloak

Write-Host "🔍 Checking user roles in Keycloak..." -ForegroundColor Green

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

# Check if testuser exists and get their roles
Write-Host "👤 Checking testuser..." -ForegroundColor Yellow
try {
    $users = Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/users?username=testuser" -Headers $headers
    if ($users.Count -gt 0) {
        $userId = $users[0].id
        Write-Host "✅ Found testuser with ID: $userId" -ForegroundColor Green
        
        # Get user's current roles
        Write-Host "🔍 Getting user's current roles..." -ForegroundColor Yellow
        $userRoles = Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/users/$userId/role-mappings/realm" -Headers $headers
        
        Write-Host "📋 Current roles for testuser:" -ForegroundColor Cyan
        if ($userRoles.Count -gt 0) {
            foreach ($role in $userRoles) {
                Write-Host "   - $($role.name)" -ForegroundColor White
            }
        } else {
            Write-Host "   ⚠️ No roles assigned!" -ForegroundColor Yellow
        }
        
        # Check available roles
        Write-Host "🔍 Getting available realm roles..." -ForegroundColor Yellow
        $allRoles = Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/roles" -Headers $headers
        Write-Host "📋 Available realm roles:" -ForegroundColor Cyan
        foreach ($role in $allRoles) {
            Write-Host "   - $($role.name)" -ForegroundColor White
        }
        
        # Try to assign USER role if not already assigned
        $hasUserRole = $userRoles | Where-Object { $_.name -eq "USER" }
        if (-not $hasUserRole) {
            Write-Host "🔐 Attempting to assign USER role..." -ForegroundColor Yellow
            try {
                # Get USER role details
                $userRole = Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/roles/USER" -Headers $headers
                
                # Prepare role assignment data
                $roleAssignment = @($userRole) | ConvertTo-Json -Depth 3
                
                # Assign role
                Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/users/$userId/role-mappings/realm" -Method Post -Body $roleAssignment -Headers $headers
                Write-Host "✅ USER role assigned successfully!" -ForegroundColor Green
            } catch {
                Write-Host "❌ Failed to assign USER role: $($_.Exception.Message)" -ForegroundColor Red
                Write-Host "Response: $($_.Exception.Response | ConvertTo-Json)" -ForegroundColor Red
            }
        } else {
            Write-Host "✅ USER role already assigned!" -ForegroundColor Green
        }
        
    } else {
        Write-Host "❌ testuser not found!" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Error checking user: $($_.Exception.Message)" -ForegroundColor Red
}
    