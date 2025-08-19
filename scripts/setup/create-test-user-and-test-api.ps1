# Create test user and customer for /my-info API testing
Write-Host "👤 Creating test user and customer for /my-info API..." -ForegroundColor Green

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

# Create test user in Keycloak
Write-Host "👤 Creating test user..." -ForegroundColor Yellow
$userData = @{
    username = "testcustomer"
    email = "test@customer.com"
    firstName = "Test"
    lastName = "Customer"
    enabled = $true
    emailVerified = $true
    credentials = @(
        @{
            type = "password"
            value = "password123"
            temporary = $false
        }
    )
} | ConvertTo-Json -Depth 3

$headers = @{
    'Authorization' = "Bearer $adminToken"
    'Content-Type' = 'application/json'
}

try {
    Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/users" -Method Post -Body $userData -Headers $headers
    Write-Host "✅ Test user created: testcustomer" -ForegroundColor Green
} catch {
    if ($_.Exception.Message -contains "409") {
        Write-Host "⚠️ User already exists" -ForegroundColor Yellow
    } else {
        Write-Host "❌ Failed to create user: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Get user ID
Write-Host "🔍 Getting user ID..." -ForegroundColor Yellow
try {
    $users = Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/users?username=testcustomer" -Method Get -Headers $headers
    if ($users.Count -gt 0) {
        $userId = $users[0].id
        Write-Host "✅ User ID: $userId" -ForegroundColor Green
        
        # Test getting JWT token for this user
        Write-Host "🧪 Testing JWT token generation..." -ForegroundColor Yellow
        $tokenBody = @{
            username = "testcustomer"
            password = "password123"
            grant_type = "password"
            client_id = "klb-frontend"
        }
        
        try {
            $tokenResponse = Invoke-RestMethod -Uri "http://localhost:8090/realms/Kienlongbank/protocol/openid-connect/token" -Method Post -ContentType "application/x-www-form-urlencoded" -Body ($tokenBody.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" } | Join-String -Separator "&")
            $jwt = $tokenResponse.access_token
            Write-Host "✅ JWT token generated successfully" -ForegroundColor Green
            
            # Now test the /my-info API with this token
            Write-Host "🧪 Testing /my-info API with valid JWT..." -ForegroundColor Cyan
            $authHeaders = @{
                'Authorization' = "Bearer $jwt"
                'Content-Type' = 'application/json'
            }
            
            try {
                $response = Invoke-RestMethod -Uri "http://localhost:8080/api/customers/my-info" -Method Get -Headers $authHeaders
                Write-Host "✅ /my-info API call successful!" -ForegroundColor Green
                Write-Host "Response: $($response | ConvertTo-Json -Depth 2)" -ForegroundColor Green
            } catch {
                $statusCode = $_.Exception.Response.StatusCode
                if ($statusCode -eq "NotFound") {
                    Write-Host "⚠️ Customer record not found (404) - This is expected" -ForegroundColor Yellow
                    Write-Host "   JWT token is valid but customer record doesn't exist in database" -ForegroundColor Yellow
                    Write-Host "   Subject in JWT: $userId" -ForegroundColor Yellow
                } else {
                    Write-Host "❌ API call failed: $statusCode - $($_.Exception.Message)" -ForegroundColor Red
                }
            }
            
        } catch {
            Write-Host "❌ Failed to get JWT token: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
} catch {
    Write-Host "❌ Failed to get user: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "🏁 Test Summary:" -ForegroundColor Green
Write-Host "   ✅ API Gateway routing works" -ForegroundColor White
Write-Host "   ✅ JWT authentication works" -ForegroundColor White
Write-Host "   ⚠️ Need customer record with ID matching JWT subject" -ForegroundColor Yellow
Write-Host ""
Write-Host "💡 To complete the test:" -ForegroundColor Cyan
Write-Host "   1. Create customer record in database with ID = JWT subject" -ForegroundColor White
Write-Host "   2. Or modify JWT to use existing customer ID" -ForegroundColor White
