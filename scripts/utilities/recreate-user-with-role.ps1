# Script to recreate user with proper role assignment

Write-Host "🔧 Recreating user with proper role assignment..." -ForegroundColor Green

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
    Write-Host "❌ Failed to get admin token" -ForegroundColor Red
    exit 1
}

$headers = @{
    "Authorization" = "Bearer $adminToken"
    "Content-Type" = "application/json"
}

# Step 1: Delete existing testuser
Write-Host "🗑️ Deleting existing testuser..." -ForegroundColor Yellow
try {
    $users = Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/users?username=testuser" -Headers $headers
    if ($users.Count -gt 0) {
        $userId = $users[0].id
        Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/users/$userId" -Method Delete -Headers $headers
        Write-Host "✅ Existing user deleted" -ForegroundColor Green
    }
} catch {
    Write-Host "⚠️ Could not delete existing user (may not exist)" -ForegroundColor Yellow
}

# Step 2: Create new user
Write-Host "👤 Creating new testuser..." -ForegroundColor Yellow
$userData = @{
    username = "testuser"
    email = "test@kienlongbank.com"
    firstName = "Test"
    lastName = "User"
    enabled = $true
    credentials = @(
        @{
            type = "password"
            value = "password123"
            temporary = $false
        }
    )
} | ConvertTo-Json -Depth 3

try {
    Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/users" -Method Post -Body $userData -Headers $headers
    Write-Host "✅ New user created" -ForegroundColor Green
    
    # Wait a moment for user creation to complete
    Start-Sleep -Seconds 2
    
} catch {
    Write-Host "❌ Failed to create user: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Step 3: Get new user ID
Write-Host "🔍 Getting new user ID..." -ForegroundColor Yellow
try {
    $users = Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/users?username=testuser" -Headers $headers
    if ($users.Count -gt 0) {
        $userId = $users[0].id
        Write-Host "✅ Got user ID: $userId" -ForegroundColor Green
    } else {
        Write-Host "❌ Could not find newly created user" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "❌ Error getting user ID: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Step 4: Get USER role
Write-Host "🔍 Getting USER role..." -ForegroundColor Yellow
try {
    $userRole = Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/roles/USER" -Headers $headers
    Write-Host "✅ Got USER role: $($userRole.id)" -ForegroundColor Green
} catch {
    Write-Host "❌ Could not get USER role: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Step 5: Assign USER role using correct format
Write-Host "🔐 Assigning USER role..." -ForegroundColor Yellow
try {
    # Use the exact same format as the successful Keycloak Admin Console would use
    $roleAssignment = "[{`"id`":`"$($userRole.id)`",`"name`":`"USER`",`"description`":`"Role for USER access`",`"composite`":false}]"
    
    Write-Host "📋 Assignment payload: $roleAssignment" -ForegroundColor Cyan
    
    $response = Invoke-WebRequest -Uri "http://localhost:8090/admin/realms/Kienlongbank/users/$userId/role-mappings/realm" -Method Post -Body $roleAssignment -Headers $headers
    
    if ($response.StatusCode -eq 204 -or $response.StatusCode -eq 200) {
        Write-Host "✅ USER role assigned successfully!" -ForegroundColor Green
    } else {
        Write-Host "⚠️ Unexpected response code: $($response.StatusCode)" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "❌ Failed to assign USER role: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Response: $($_.Exception.Response.StatusCode)" -ForegroundColor Yellow
}

# Step 6: Verify assignment
Write-Host "🔍 Verifying role assignment..." -ForegroundColor Yellow
try {
    $assignedRoles = Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/users/$userId/role-mappings/realm" -Headers $headers
    
    Write-Host "📋 Assigned roles:" -ForegroundColor Cyan
    $hasUserRole = $false
    foreach ($role in $assignedRoles) {
        if ($role.name -eq "USER") {
            Write-Host "   ✅ $($role.name)" -ForegroundColor Green
            $hasUserRole = $true
        } else {
            Write-Host "   ℹ️ $($role.name)" -ForegroundColor White
        }
    }
    
    if ($hasUserRole) {
        Write-Host ""
        Write-Host "🎉 SUCCESS: USER role has been assigned to testuser!" -ForegroundColor Green
    } else {
        Write-Host ""
        Write-Host "❌ FAILED: USER role was not assigned" -ForegroundColor Red
    }
    
} catch {
    Write-Host "❌ Error verifying assignment: $($_.Exception.Message)" -ForegroundColor Red
}
