#!/usr/bin/env pwsh
<#
.SYNOPSIS
    API Endpoint Tester
    
.DESCRIPTION
    Test specific API endpoint với custom data
    
.EXAMPLE
    .\test-endpoint.ps1 -Url "http://localhost:8080/api/accounts" -Method GET
    .\test-endpoint.ps1 -Url "http://localhost:8082/api/customers" -Method POST -Data '{"firstName":"John","lastName":"Doe"}'
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Url,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("GET", "POST", "PUT", "DELETE", "PATCH")]
    [string]$Method = "GET",
    
    [Parameter(Mandatory=$false)]
    [string]$Data = "",
    
    [Parameter(Mandatory=$false)]
    [string]$PhoneNumber = "0987654321",
    
    [Parameter(Mandatory=$false)]
    [string]$Password = "password123",
    
    [Parameter(Mandatory=$false)]
    [switch]$NoAuth,
    
    [Parameter(Mandatory=$false)]
    [switch]$Pretty
)

function Get-Token {
    param([string]$User, [string]$Pass)
    
    $tokenUrl = "http://localhost:8090/realms/Kienlongbank/protocol/openid-connect/token"
    $body = @{
        'grant_type' = 'password'
        'client_id' = 'klb-frontend'
        'username' = $User
        'password' = $Pass
    }
    
    try {
        $response = Invoke-RestMethod -Uri $tokenUrl -Method POST -Body $body -ContentType "application/x-www-form-urlencoded"
        return $response.access_token
    }
    catch {
        Write-Error "Failed to get token: $($_.Exception.Message)"
        return $null
    }
}

# Main execution
Write-Host "🧪 Testing API Endpoint" -ForegroundColor Blue
Write-Host "URL: $Url" -ForegroundColor Cyan
Write-Host "Method: $Method" -ForegroundColor Cyan

# Prepare headers
$headers = @{ 'Content-Type' = 'application/json' }

# Get token if auth required
if (-not $NoAuth) {
    Write-Host "Getting authentication token..." -ForegroundColor Yellow
    $token = Get-Token -User $PhoneNumber -Pass $Password
    if ($token) {
        $headers['Authorization'] = "Bearer $token"
        Write-Host "✅ Token obtained" -ForegroundColor Green
    } else {
        Write-Host "❌ Failed to get token" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "⚠️ Running without authentication" -ForegroundColor Yellow
}

# Prepare request
$requestParams = @{
    Uri = $Url
    Method = $Method
    Headers = $headers
    TimeoutSec = 30
}

# Add body if provided
if ($Data) {
    Write-Host "Request Body:" -ForegroundColor Yellow
    if ($Pretty) {
        try {
            $jsonData = $Data | ConvertFrom-Json | ConvertTo-Json -Depth 5
            Write-Host $jsonData -ForegroundColor Gray
        } catch {
            Write-Host $Data -ForegroundColor Gray
        }
    } else {
        Write-Host $Data -ForegroundColor Gray
    }
    $requestParams.Body = $Data
}

# Execute request
Write-Host "`n🚀 Executing request..." -ForegroundColor Blue
$startTime = Get-Date

try {
    $response = Invoke-RestMethod @requestParams
    $endTime = Get-Date
    $duration = ($endTime - $startTime).TotalMilliseconds
    
    Write-Host "✅ SUCCESS (${duration}ms)" -ForegroundColor Green
    
    Write-Host "`nResponse:" -ForegroundColor Yellow
    if ($Pretty -and $response) {
        $response | ConvertTo-Json -Depth 5 | Write-Host -ForegroundColor Green
    } else {
        $response | Write-Host -ForegroundColor Green
    }
    
} catch {
    $endTime = Get-Date
    $duration = ($endTime - $startTime).TotalMilliseconds
    $statusCode = $_.Exception.Response.StatusCode.value__
    
    Write-Host "❌ FAILED (${duration}ms)" -ForegroundColor Red
    Write-Host "Status Code: $statusCode" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    
    if ($_.Exception.Response) {
        try {
            $errorStream = $_.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($errorStream)
            $errorBody = $reader.ReadToEnd()
            if ($errorBody) {
                Write-Host "Error Response:" -ForegroundColor Yellow
                if ($Pretty) {
                    try {
                        $errorBody | ConvertFrom-Json | ConvertTo-Json -Depth 3 | Write-Host -ForegroundColor Red
                    } catch {
                        Write-Host $errorBody -ForegroundColor Red
                    }
                } else {
                    Write-Host $errorBody -ForegroundColor Red
                }
            }
        } catch {
            # Ignore errors reading error response
        }
    }
}

Write-Host "`n💡 Examples:" -ForegroundColor Yellow
Write-Host "  GET:    .\test-endpoint.ps1 -Url 'http://localhost:8080/api/accounts' -Method GET" -ForegroundColor Gray
Write-Host "  POST:   .\test-endpoint.ps1 -Url 'http://localhost:8082/api/customers' -Method POST -Data '{\"firstName\":\"John\"}'" -ForegroundColor Gray
Write-Host "  NoAuth: .\test-endpoint.ps1 -Url 'http://localhost:8080/actuator/health' -NoAuth" -ForegroundColor Gray
Write-Host "  Admin:  .\test-endpoint.ps1 -Url 'http://localhost:8080/api/accounts' -Username 'admin' -Password 'admin123'" -ForegroundColor Gray
