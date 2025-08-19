#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Create admin user for KLB Banking System
    
.DESCRIPTION
    This script creates an admin user with ADMIN role in Keycloak
#>

Write-Host "🔧 Creating admin user for KLB Banking System..." -ForegroundColor Green

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

# Create admin user
Write-Host "👤 Creating admin user..." -ForegroundColor Yellow
$adminUserData = @{
    username = "adminuser"
    firstName = "Admin"
    lastName = "User"
    email = "admin@kienlongbank.com"
    emailVerified = $true
    enabled = $true
    credentials = @(
        @{
            type = "password"
            value = "admin123"
            temporary = $false
        }
    )
} | ConvertTo-Json -Depth 3

try {
    Invoke-WebRequest -Uri "http://localhost:8090/admin/realms/Kienlongbank/users" -Method Post -Body $adminUserData -Headers $headers -UseBasicParsing
    Write-Host "✅ Admin user created" -ForegroundColor Green
} catch {
    $errorResponse = $_.Exception.Response
    if ($errorResponse.StatusCode -eq 409) {
        Write-Host "⚠️ Admin user already exists" -ForegroundColor Yellow
    } else {
        Write-Host "❌ Failed to create admin user: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

# Assign ADMIN role to admin user
Write-Host "🔐 Assigning ADMIN role to admin user..." -ForegroundColor Yellow
try {
    # Get admin user ID
    $users = Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/users?username=adminuser" -Headers $headers
    if ($users.Count -gt 0) {
        $userId = $users[0].id
        
        # Get ADMIN role
        $adminRole = Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/roles/ADMIN" -Headers $headers
        
        # Assign role
        $roleAssignmentData = @(
            @{
                id = $adminRole.id
                name = "ADMIN"
                composite = $false
                clientRole = $false
            }
        ) | ConvertTo-Json -Depth 2
        
        Invoke-WebRequest -Uri "http://localhost:8090/admin/realms/Kienlongbank/users/$userId/role-mappings/realm" -Method Post -Body $roleAssignmentData -Headers $headers -UseBasicParsing
        Write-Host "✅ ADMIN role assigned to adminuser" -ForegroundColor Green
    }
} catch {
    Write-Host "❌ Failed to assign ADMIN role: $($_.Exception.Message)" -ForegroundColor Red
}

# Verify role assignment
Write-Host "🔍 Verifying admin role assignment..." -ForegroundColor Yellow
try {
    $users = Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/users?username=adminuser" -Headers $headers
    if ($users.Count -gt 0) {
        $userId = $users[0].id
        $assignedRoles = Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/users/$userId/role-mappings/realm" -Headers $headers
        
        $hasAdminRole = $assignedRoles | Where-Object { $_.name -eq "ADMIN" }
        if ($hasAdminRole) {
            Write-Host "✅ Role assignment verified: ADMIN role is active" -ForegroundColor Green
        } else {
            Write-Host "⚠️ Role assignment verification failed: ADMIN role not found" -ForegroundColor Yellow
        }
    }
} catch {
    Write-Host "⚠️ Could not verify role assignment: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🎉 Admin user creation complete!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Admin User Details:" -ForegroundColor Cyan
Write-Host "   Username: adminuser" -ForegroundColor White
Write-Host "   Password: admin123" -ForegroundColor White
Write-Host "   Role: ADMIN" -ForegroundColor White
Write-Host "   Email: admin@kienlongbank.com" -ForegroundColor White
Write-Host ""
