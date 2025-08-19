#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Test API from inside Docker network
    
.DESCRIPTION
    This script runs a temporary container to test API from inside Docker network
#>

Write-Host "🐳 Testing API from inside Docker network..." -ForegroundColor Cyan

# Run a temporary container to test from inside Docker network
$testScript = @"
#!/bin/bash
echo "🔑 Getting token from inside Docker network..."

# Get token using container hostname
TOKEN_RESPONSE=`$(curl -s -X POST 'http://klb-keycloak:8080/realms/Kienlongbank/protocol/openid-connect/token' \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d 'grant_type=password&client_id=klb-frontend&username=testuser&password=password123')

echo "Token response: `$TOKEN_RESPONSE"

if [[ "`$TOKEN_RESPONSE" == *"access_token"* ]]; then
  TOKEN=`$(echo "`$TOKEN_RESPONSE" | grep -o '"access_token":"[^"]*' | sed 's/"access_token":"//')
  echo "✅ Token obtained from internal network"
  
  echo "🧪 Testing API endpoint..."
  API_RESPONSE=`$(curl -s -X GET 'http://klb-api-gateway:8080/api/accounts' \
    -H "Authorization: Bearer `$TOKEN" \
    -H 'Content-Type: application/json' -w "HTTP_STATUS:%{http_code}")
  
  echo "API Response: `$API_RESPONSE"
else
  echo "❌ Failed to get token"
fi
"@

# Write script to temporary file
$scriptPath = "docker-test-script.sh"
$testScript | Out-File -FilePath $scriptPath -Encoding utf8

try {
    Write-Host "🚀 Running test container..." -ForegroundColor Yellow
    
    # Run the test using a temporary container in the same network
    $output = docker run --rm --network kienlongbank-project_default -v "${PWD}/${scriptPath}:/test.sh" ubuntu:latest bash /test.sh
    
    Write-Host $output -ForegroundColor White
    
} catch {
    Write-Host "❌ Error running container test: $($_.Exception.Message)" -ForegroundColor Red
} finally {
    # Cleanup
    if (Test-Path $scriptPath) {
        Remove-Item $scriptPath
    }
}
