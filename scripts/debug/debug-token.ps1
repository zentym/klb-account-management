#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Decode JWT Token and test API with details
    
.DESCRIPTION
    This script gets JWT token, decodes it, and tests API endpoints
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$Username = "0901234567",
    
    [Parameter(Mandatory = $false)]
    [string]$Password = "admin123"
)

function Decode-JWTToken {
    param([string]$Token)
    
    $parts = $Token.Split('.')
    if ($parts.Length -ne 3) {
        Write-Host "Invalid JWT token format" -ForegroundColor Red
        return
    }
    
    try {
        # Decode payload (add padding if needed)
        $payloadPart = $parts[1]
        
        # Add padding to make length multiple of 4
        $padding = 4 - ($payloadPart.Length % 4)
        if ($padding -ne 4) {
            $payloadPart += ("=" * $padding)
        }
        
        $payloadBytes = [System.Convert]::FromBase64String($payloadPart)
        $payload = [System.Text.Encoding]::UTF8.GetString($payloadBytes) | ConvertFrom-Json
        
        Write-Host "🔍 JWT Token Details:" -ForegroundColor Cyan
        Write-Host "   Subject: $($payload.sub)" -ForegroundColor White
        Write-Host "   Username: $($payload.preferred_username)" -ForegroundColor White
        if ($payload.realm_access -and $payload.realm_access.roles) {
            Write-Host "   Realm Roles: $($payload.realm_access.roles -join ', ')" -ForegroundColor White
        } else {
            Write-Host "   Realm Roles: No roles found" -ForegroundColor Yellow
        }
        Write-Host "   Issuer: $($payload.iss)" -ForegroundColor White
        Write-Host "   Expires: $([DateTimeOffset]::FromUnixTimeSeconds($payload.exp).ToString())" -ForegroundColor White
        
        return $payload
    } catch {
        Write-Host "Failed to decode token: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Token part length: $($payloadPart.Length)" -ForegroundColor Yellow
    }
}

# Get JWT token
Write-Host "🔑 Getting JWT token from Keycloak..." -ForegroundColor Blue

$tokenUrl = "http://localhost:8090/realms/Kienlongbank/protocol/openid-connect/token"
$body = @{
    'grant_type' = 'password'
    'client_id'  = 'klb-frontend'
    'username'   = $Username
    'password'   = $Password
}

try {
    $response = Invoke-RestMethod -Uri $tokenUrl -Method POST -Body $body -ContentType "application/x-www-form-urlencoded"
    Write-Host "✅ Token obtained successfully" -ForegroundColor Green
    $token = $response.access_token
    
    # Decode token
    $payload = Decode-JWTToken -Token $token
    
    # Test a simple API endpoint
    Write-Host "`n🧪 Testing API endpoint with token..." -ForegroundColor Cyan
    
    $headers = @{
        'Authorization' = "Bearer $token"
        'Content-Type' = 'application/json'
    }
    
    try {
        Write-Host "Testing: GET http://localhost:8080/api/accounts" -ForegroundColor Yellow
        $apiResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/accounts" -Method GET -Headers $headers
        Write-Host "✅ API call successful" -ForegroundColor Green
        Write-Host "Response: $($apiResponse | ConvertTo-Json -Depth 2)" -ForegroundColor White
    } catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        $errorMessage = $_.Exception.Message
        Write-Host "❌ API call failed ($statusCode): $errorMessage" -ForegroundColor Red
        
        # Try to get more details
        if ($_.Exception.Response) {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $responseBody = $reader.ReadToEnd()
            Write-Host "Error Response: $responseBody" -ForegroundColor Red
        }
    }
    
} catch {
    Write-Host "❌ Failed to get token: $($_.Exception.Message)" -ForegroundColor Red
}
