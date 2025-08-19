# PowerShell script to configure Keycloak for KLB Frontend

Write-Host "🔧 Configuring Keycloak for KLB Frontend..." -ForegroundColor Green

# Wait for Keycloak to be ready
Write-Host "⏳ Waiting for Keycloak to start..." -ForegroundColor Yellow
do {
    Start-Sleep -Seconds 2
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8090/realms/master/.well-known/openid-configuration" -UseBasicParsing -ErrorAction SilentlyContinue
        $ready = $response.StatusCode -eq 200
    } catch {
        $ready = $false
    }
} while (-not $ready)

Write-Host "✅ Keycloak is ready!" -ForegroundColor Green

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

# Create Kienlongbank realm
Write-Host "🏗️ Creating Kienlongbank realm..." -ForegroundColor Yellow
$realmData = @{
    realm = "Kienlongbank"
    enabled = $true
    displayName = "Kien Long Bank"
    accessCodeLifespan = 300
    accessTokenLifespan = 3600
    refreshTokenMaxReuse = 0
    ssoSessionIdleTimeout = 1800
    ssoSessionMaxLifespan = 36000
} | ConvertTo-Json

$headers = @{
    "Authorization" = "Bearer $adminToken"
    "Content-Type" = "application/json"
}

try {
    Invoke-RestMethod -Uri "http://localhost:8090/admin/realms" -Method Post -Body $realmData -Headers $headers
    Write-Host "✅ Realm created" -ForegroundColor Green
} catch {
    if ($_.Exception.Response.StatusCode -eq 409) {
        Write-Host "ℹ️ Realm already exists" -ForegroundColor Blue
    } else {
        Write-Host "❌ Failed to create realm: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Create klb-frontend client
Write-Host "🔧 Creating klb-frontend client..." -ForegroundColor Yellow
$clientData = @{
    clientId = "klb-frontend"
    name = "KLB Frontend Application"
    enabled = $true
    publicClient = $true
    directAccessGrantsEnabled = $true
    standardFlowEnabled = $true
    implicitFlowEnabled = $false
    serviceAccountsEnabled = $false
    redirectUris = @("http://localhost:3000/*")
    webOrigins = @("http://localhost:3000")
    protocol = "openid-connect"
} | ConvertTo-Json

try {
    Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/clients" -Method Post -Body $clientData -Headers $headers
    Write-Host "✅ Frontend client created" -ForegroundColor Green
} catch {
    if ($_.Exception.Response.StatusCode -eq 409) {
        Write-Host "ℹ️ Frontend client already exists" -ForegroundColor Blue
    } else {
        Write-Host "❌ Failed to create frontend client: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Create klb-backend-api client (confidential)
Write-Host "🔧 Creating klb-backend-api client..." -ForegroundColor Yellow
$backendClientData = @{
    clientId = "klb-backend-api"
    name = "KLB Backend API"
    enabled = $true
    publicClient = $false
    directAccessGrantsEnabled = $true
    standardFlowEnabled = $true
    implicitFlowEnabled = $false
    serviceAccountsEnabled = $true
    bearerOnly = $false
    protocol = "openid-connect"
    attributes = @{
        "access.token.lifespan" = "3600"
    }
} | ConvertTo-Json -Depth 3

try {
    Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/clients" -Method Post -Body $backendClientData -Headers $headers
    Write-Host "✅ Backend client created" -ForegroundColor Green
} catch {
    if ($_.Exception.Response.StatusCode -eq 409) {
        Write-Host "ℹ️ Backend client already exists" -ForegroundColor Blue
    } else {
        Write-Host "❌ Failed to create backend client: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Create realm roles
Write-Host "🔧 Creating realm roles..." -ForegroundColor Yellow
$roles = @("USER", "ADMIN")

foreach ($roleName in $roles) {
    $roleData = @{
        name = $roleName
        description = "Role for $roleName access"
    } | ConvertTo-Json
    
    try {
        Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/roles" -Method Post -Body $roleData -Headers $headers
        Write-Host "✅ Role '$roleName' created" -ForegroundColor Green
    } catch {
        if ($_.Exception.Response.StatusCode -eq 409) {
            Write-Host "ℹ️ Role '$roleName' already exists" -ForegroundColor Blue
        } else {
            Write-Host "❌ Failed to create role '$roleName': $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# Create test user
Write-Host "👤 Creating test user..." -ForegroundColor Yellow
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
    Write-Host "✅ Test user created" -ForegroundColor Green
} catch {
    if ($_.Exception.Response.StatusCode -eq 409) {
        Write-Host "ℹ️ User already exists" -ForegroundColor Blue
    } else {
        Write-Host "❌ Failed to create user: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Assign USER role to test user
Write-Host "🔐 Assigning USER role to test user..." -ForegroundColor Yellow
try {
    # Get user ID
    $users = Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/users?username=testuser" -Headers $headers
    if ($users.Count -gt 0) {
        $userId = $users[0].id
        
        # Get USER role
        $userRole = Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/roles/USER" -Headers $headers
        
        # Check if user already has USER role
        $currentRoles = Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/users/$userId/role-mappings/realm" -Headers $headers
        $hasUserRole = $currentRoles | Where-Object { $_.name -eq "USER" }
        
        if ($hasUserRole) {
            Write-Host "✅ USER role already assigned to testuser" -ForegroundColor Green
        } else {
            # Use correct format for role assignment
            $roleAssignment = "[{`"id`":`"$($userRole.id)`",`"name`":`"USER`",`"description`":`"Role for USER access`",`"composite`":false}]"
            
            $response = Invoke-WebRequest -Uri "http://localhost:8090/admin/realms/Kienlongbank/users/$userId/role-mappings/realm" -Method Post -Body $roleAssignment -Headers $headers -UseBasicParsing
            
            if ($response.StatusCode -eq 204 -or $response.StatusCode -eq 200) {
                Write-Host "✅ USER role assigned to testuser" -ForegroundColor Green
            } else {
                Write-Host "⚠️ Unexpected response code: $($response.StatusCode)" -ForegroundColor Yellow
            }
        }
    }
} catch {
    Write-Host "⚠️ Could not assign USER role: $($_.Exception.Message)" -ForegroundColor Yellow
    # Try alternative approach if first method fails
    Write-Host "🔄 Trying alternative role assignment method..." -ForegroundColor Yellow
    try {
        Start-Sleep -Seconds 1
        $users = Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/users?username=testuser" -Headers $headers
        if ($users.Count -gt 0) {
            $userId = $users[0].id
            $userRole = Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/roles/USER" -Headers $headers
            
            # Simple role assignment with minimal data
            $simpleRoleData = @(
                @{
                    id = $userRole.id
                    name = "USER"
                }
            ) | ConvertTo-Json -Depth 2 -Compress
            
            Invoke-WebRequest -Uri "http://localhost:8090/admin/realms/Kienlongbank/users/$userId/role-mappings/realm" -Method Post -Body $simpleRoleData -Headers $headers -UseBasicParsing
            Write-Host "✅ USER role assigned via alternative method" -ForegroundColor Green
        }
    } catch {
        Write-Host "❌ Failed to assign USER role via alternative method" -ForegroundColor Red
    }
}

# Verify role assignment
Write-Host "🔍 Verifying role assignment..." -ForegroundColor Yellow
try {
    $users = Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/users?username=testuser" -Headers $headers
    if ($users.Count -gt 0) {
        $userId = $users[0].id
        $assignedRoles = Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/users/$userId/role-mappings/realm" -Headers $headers
        
        $hasUserRole = $assignedRoles | Where-Object { $_.name -eq "USER" }
        if ($hasUserRole) {
            Write-Host "✅ Role assignment verified: USER role is active" -ForegroundColor Green
        } else {
            Write-Host "⚠️ Role assignment verification failed: USER role not found" -ForegroundColor Yellow
        }
    }
} catch {
    Write-Host "⚠️ Could not verify role assignment: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🎉 Keycloak configuration complete!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Configuration Summary:" -ForegroundColor Cyan
Write-Host "   Realm: Kienlongbank" -ForegroundColor White
Write-Host "   Frontend Client ID: klb-frontend (public)" -ForegroundColor White
Write-Host "   Backend Client ID: klb-backend-api (confidential)" -ForegroundColor White
Write-Host "   Roles: USER, ADMIN" -ForegroundColor White
Write-Host "   Test User: testuser / password123 (with USER role)" -ForegroundColor White
Write-Host "   Keycloak URL: http://localhost:8090" -ForegroundColor White
Write-Host ""
Write-Host "🚀 You can now start the frontend and backend services!" -ForegroundColor Green
