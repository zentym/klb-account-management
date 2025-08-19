#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Test API with corrected issuer URI
    
.DESCRIPTION
    This script tests API with token that has matching issuer
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$Username = "testuser",
    
    [Parameter(Mandatory = $false)]
    [string]$Password = "password123"
)

# Test with internal Docker host
Write-Host "🔧 Testing with host.docker.internal issuer..." -ForegroundColor Cyan

# However, we need to get token from localhost (outside docker)
# but the backend services expect host.docker.internal

# First, let's check if we can access keycloak via host.docker.internal from outside
Write-Host "🔍 Checking Keycloak connectivity..." -ForegroundColor Yellow

try {
    $response = Invoke-RestMethod -Uri "http://host.docker.internal:8090/realms/Kienlongbank/.well-known/openid-configuration" -Method GET -TimeoutSec 5
    Write-Host "✅ host.docker.internal works from outside Docker" -ForegroundColor Green
    $issuerUri = "http://host.docker.internal:8090/realms/Kienlongbank"
} catch {
    Write-Host "⚠️ host.docker.internal not accessible, using localhost" -ForegroundColor Yellow
    $issuerUri = "http://localhost:8090/realms/Kienlongbank"
}

# Get token
Write-Host "🔑 Getting JWT token..." -ForegroundColor Blue
$tokenUrl = "$issuerUri/protocol/openid-connect/token"
$body = @{
    'grant_type' = 'password'
    'client_id'  = 'klb-frontend'
    'username'   = $Username
    'password'   = $Password
}

try {
    $response = Invoke-RestMethod -Uri $tokenUrl -Method POST -Body $body -ContentType "application/x-www-form-urlencoded"
    $token = $response.access_token
    Write-Host "✅ Token obtained successfully" -ForegroundColor Green
    
    # Test API
    Write-Host "🧪 Testing API with token..." -ForegroundColor Cyan
    $headers = @{
        'Authorization' = "Bearer $token"
        'Content-Type' = 'application/json'
    }
    
    try {
        Write-Host "Testing: GET http://localhost:8080/api/accounts" -ForegroundColor Yellow
        $apiResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/accounts" -Method GET -Headers $headers
        Write-Host "✅ API call successful!" -ForegroundColor Green
        Write-Host "Response: $($apiResponse | ConvertTo-Json -Depth 2)" -ForegroundColor White
    } catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        $errorMessage = $_.Exception.Message
        Write-Host "❌ API call failed ($statusCode): $errorMessage" -ForegroundColor Red
    }
    
} catch {
    Write-Host "❌ Failed to get token: $($_.Exception.Message)" -ForegroundColor Red
}
