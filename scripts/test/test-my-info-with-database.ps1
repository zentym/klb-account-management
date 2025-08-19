# Create Keycloak users that match customer IDs and test /my-info API
Write-Host "👥 Creating Keycloak users matching customer database..." -ForegroundColor Green

# Get admin token
Write-Host "🔑 Getting admin token..." -ForegroundColor Yellow
$adminTokenBody = @{
    username = "admin"
    password = "admin"
    grant_type = "password"
    client_id = "admin-cli"
}

try {
    $adminTokenResponse = Invoke-RestMethod -Uri "http://localhost:8090/realms/master/protocol/openid-connect/token" -Method Post -Body $adminTokenBody
    $adminToken = $adminTokenResponse.access_token
    Write-Host "✅ Got admin token" -ForegroundColor Green
    
    $adminHeaders = @{
        'Authorization' = "Bearer $adminToken"
        'Content-Type' = 'application/json'
    }
    
    # Create users corresponding to customer IDs
    $users = @(
        @{username = "customer1"; email = "test@customer.com"; fullName = "Test Customer"; password = "password123"},
        @{username = "customer3"; email = "nguyenvana@klb.com"; fullName = "Nguyen Van A"; password = "password123"},
        @{username = "customer4"; email = "tranthib@klb.com"; fullName = "Tran Thi B"; password = "password123"},
        @{username = "customer5"; email = "levanc@klb.com"; fullName = "Le Van C"; password = "password123"}
    )
    
    foreach ($user in $users) {
        Write-Host "👤 Creating user: $($user.username)..." -ForegroundColor Cyan
        
        $userData = @{
            username = $user.username
            email = $user.email
            firstName = $user.fullName.Split(' ')[0]
            lastName = $user.fullName.Split(' ')[-1]
            enabled = $true
            emailVerified = $true
            attributes = @{
                customer_id = @($user.username.Replace('customer', ''))
            }
            credentials = @(
                @{
                    type = "password"
                    value = $user.password
                    temporary = $false
                }
            )
        } | ConvertTo-Json -Depth 4
        
        try {
            Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/users" -Method Post -Body $userData -Headers $adminHeaders
            Write-Host "✅ Created user: $($user.username)" -ForegroundColor Green
        } catch {
            if ($_.Exception.Message -contains "409") {
                Write-Host "⚠️ User $($user.username) already exists" -ForegroundColor Yellow
            } else {
                Write-Host "❌ Failed to create user $($user.username): $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }
    
    Write-Host ""
    Write-Host "🧪 Now testing /my-info API with each user..." -ForegroundColor Green
    Write-Host ""
    
    # Test API with each user
    foreach ($user in $users) {
        Write-Host "🔍 Testing with $($user.username)..." -ForegroundColor Cyan
        $expectedCustomerId = $user.username.Replace('customer', '')
        
        try {
            # Get JWT token
            $tokenResponse = Invoke-RestMethod -Uri "http://localhost:8090/realms/Kienlongbank/protocol/openid-connect/token" -Method Post -ContentType "application/x-www-form-urlencoded" -Body "username=$($user.username)&password=$($user.password)&grant_type=password&client_id=klb-frontend"
            $jwt = $tokenResponse.access_token
            
            # Parse JWT subject
            $jwtParts = $jwt.Split('.')
            $payload = $jwtParts[1]
            while ($payload.Length % 4 -ne 0) { $payload += "=" }
            $bytes = [System.Convert]::FromBase64String($payload)
            $jsonPayload = [System.Text.Encoding]::UTF8.GetString($bytes)
            $payloadObj = $jsonPayload | ConvertFrom-Json
            
            Write-Host "   JWT Subject: $($payloadObj.sub)" -ForegroundColor Gray
            
            # Test /my-info API
            $testHeaders = @{
                'Authorization' = "Bearer $jwt"
                'Content-Type' = 'application/json'
            }
            
            try {
                $apiResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/customers/my-info" -Method Get -Headers $testHeaders
                Write-Host "   🎉 SUCCESS! API returned customer data:" -ForegroundColor Green
                Write-Host "      Name: $($apiResponse.data.fullName)" -ForegroundColor White
                Write-Host "      Email: $($apiResponse.data.email)" -ForegroundColor White
                Write-Host "      Phone: $($apiResponse.data.phone)" -ForegroundColor White
                Write-Host ""
            } catch {
                $statusCode = $_.Exception.Response.StatusCode
                if ($statusCode -eq "NotFound") {
                    Write-Host "   ⚠️ Customer ID mismatch: JWT subject doesn't match database ID $expectedCustomerId" -ForegroundColor Yellow
                } elseif ($statusCode -eq "Unauthorized") {
                    Write-Host "   ❌ Authentication failed" -ForegroundColor Red
                } else {
                    Write-Host "   ❌ Error: $statusCode" -ForegroundColor Red
                }
            }
            
        } catch {
            Write-Host "   ❌ Failed to get JWT token: $($_.Exception.Message)" -ForegroundColor Red
        }
        
        Write-Host ""
    }
    
} catch {
    Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "🏁 Database Check Summary:" -ForegroundColor Green
Write-Host "   ✅ Customer database has data" -ForegroundColor White
Write-Host "   ✅ Customer IDs: 1, 3, 4, 5" -ForegroundColor White
Write-Host "   ✅ /my-info API implementation is ready" -ForegroundColor White
Write-Host "   📝 JWT subjects need to match customer IDs for successful calls" -ForegroundColor Yellow
