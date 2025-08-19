# Manual fix for testuser role using direct Keycloak Admin API

Write-Host "🔧 Manual fix for testuser role assignment..." -ForegroundColor Green

# Get admin token
$tokenBody = @{
    username = "admin"
    password = "admin"
    grant_type = "password"
    client_id = "admin-cli"
}

$tokenResponse = Invoke-RestMethod -Uri "http://localhost:8090/realms/master/protocol/openid-connect/token" -Method Post -Body $tokenBody
$adminToken = $tokenResponse.access_token

$headers = @{
    "Authorization" = "Bearer $adminToken"
    "Content-Type" = "application/json"
}

# Get testuser ID
$users = Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/users?username=testuser" -Headers $headers
$userId = $users[0].id

Write-Host "User ID: $userId" -ForegroundColor Blue

# Try a different approach - use array format
Write-Host "🔐 Trying simplified role assignment..." -ForegroundColor Yellow

$simpleRoleData = '[{"id":"bfc3a555-0e4d-4bac-8a9c-45d17ef5e2b3","name":"USER"}]'

try {
    Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/users/$userId/role-mappings/realm" -Method Post -Body $simpleRoleData -Headers $headers
    Write-Host "✅ USER role assigned successfully!" -ForegroundColor Green
} catch {
    Write-Host "❌ Still failed: $($_.Exception.Message)" -ForegroundColor Red
    
    # Let's try to see what the exact error is
    try {
        $errorDetails = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($errorDetails)
        $responseBody = $reader.ReadToEnd()
        Write-Host "Error response body: $responseBody" -ForegroundColor Red
    } catch {
        Write-Host "Could not read error details" -ForegroundColor Yellow
    }
}

# Verify the result
Write-Host "🔍 Checking final roles..." -ForegroundColor Yellow
$finalRoles = Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/users/$userId/role-mappings/realm" -Headers $headers
Write-Host "Final roles: $($finalRoles.name -join ', ')" -ForegroundColor Blue

Write-Host ""
Write-Host "⚠️ If this still doesn't work, please:" -ForegroundColor Yellow
Write-Host "1. Go to http://localhost:8090" -ForegroundColor White
Write-Host "2. Login as admin/admin" -ForegroundColor White
Write-Host "3. Go to Kienlongbank realm > Users > testuser > Role mapping" -ForegroundColor White
Write-Host "4. Assign 'USER' role manually" -ForegroundColor White
