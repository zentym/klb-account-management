# Script to fix user role assignment in Keycloak

Write-Host "🔧 Fixing user role assignment in Keycloak..." -ForegroundColor Green

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

# Get testuser
Write-Host "👤 Getting testuser..." -ForegroundColor Yellow
try {
    $users = Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/users?username=testuser" -Headers $headers
    if ($users.Count -gt 0) {
        $userId = $users[0].id
        Write-Host "✅ Found testuser with ID: $userId" -ForegroundColor Green
        
        # Get USER role details
        Write-Host "🔍 Getting USER role details..." -ForegroundColor Yellow
        $userRole = Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/roles/USER" -Headers $headers
        Write-Host "✅ USER role details:" -ForegroundColor Green
        Write-Host "   ID: $($userRole.id)" -ForegroundColor White
        Write-Host "   Name: $($userRole.name)" -ForegroundColor White
        
        # Check current role mappings
        Write-Host "🔍 Getting current role mappings..." -ForegroundColor Yellow
        $currentRoles = Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/users/$userId/role-mappings/realm" -Headers $headers
        $hasUserRole = $currentRoles | Where-Object { $_.name -eq "USER" }
        
        if ($hasUserRole) {
            Write-Host "✅ USER role is already assigned!" -ForegroundColor Green
        } else {
            Write-Host "🔐 Assigning USER role..." -ForegroundColor Yellow
            
            # Create proper role assignment array
            $roleToAssign = @(
                @{
                    id = $userRole.id
                    name = $userRole.name
                    description = $userRole.description
                    composite = $userRole.composite
                    containerId = $userRole.containerId
                }
            )
            
            $roleAssignmentJson = $roleToAssign | ConvertTo-Json -Depth 3
            Write-Host "📋 Role assignment JSON:" -ForegroundColor Cyan
            Write-Host $roleAssignmentJson -ForegroundColor White
            
            try {
                Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/users/$userId/role-mappings/realm" -Method Post -Body $roleAssignmentJson -Headers $headers
                Write-Host "✅ USER role assigned successfully!" -ForegroundColor Green
                
                # Verify assignment
                Write-Host "🔍 Verifying role assignment..." -ForegroundColor Yellow
                $updatedRoles = Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/users/$userId/role-mappings/realm" -Headers $headers
                $verifyUserRole = $updatedRoles | Where-Object { $_.name -eq "USER" }
                
                if ($verifyUserRole) {
                    Write-Host "✅ Role assignment verified!" -ForegroundColor Green
                } else {
                    Write-Host "❌ Role assignment verification failed!" -ForegroundColor Red
                }
                
            } catch {
                Write-Host "❌ Failed to assign USER role: $($_.Exception.Message)" -ForegroundColor Red
                
                # Try to get more detailed error
                if ($_.Exception.Response) {
                    try {
                        $errorStream = $_.Exception.Response.GetResponseStream()
                        $reader = New-Object System.IO.StreamReader($errorStream)
                        $errorContent = $reader.ReadToEnd()
                        Write-Host "📋 Error details: $errorContent" -ForegroundColor Yellow
                    } catch {
                        Write-Host "Could not read error details" -ForegroundColor Yellow
                    }
                }
            }
        }
        
        # Final status check
        Write-Host ""
        Write-Host "📋 Final role status for testuser:" -ForegroundColor Cyan
        $finalRoles = Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/users/$userId/role-mappings/realm" -Headers $headers
        foreach ($role in $finalRoles) {
            $status = if ($role.name -eq "USER") { "✅" } else { "ℹ️" }
            Write-Host "   $status $($role.name)" -ForegroundColor White
        }
        
    } else {
        Write-Host "❌ testuser not found!" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
}
