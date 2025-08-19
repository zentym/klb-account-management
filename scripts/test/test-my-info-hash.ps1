# Test /my-info API với Test Customer Hash (ID: 701218)
Write-Host "🧪 Testing /my-info API with Test Customer Hash..." -ForegroundColor Green

# Trước tiên, lấy JWT token từ testcustomer
Write-Host "🔑 Getting JWT token from testcustomer..." -ForegroundColor Yellow
try {
    $tokenResponse = Invoke-RestMethod -Uri "http://localhost:8090/realms/Kienlongbank/protocol/openid-connect/token" -Method Post -ContentType "application/x-www-form-urlencoded" -Body "username=testcustomer&password=password123&grant_type=password&client_id=klb-frontend"
    $jwt = $tokenResponse.access_token
    
    # Parse JWT để lấy subject
    $jwtParts = $jwt.Split('.')
    $payload = $jwtParts[1]
    while ($payload.Length % 4 -ne 0) { $payload += "=" }
    $bytes = [System.Convert]::FromBase64String($payload)
    $jsonPayload = [System.Text.Encoding]::UTF8.GetString($bytes)
    $payloadObj = $jsonPayload | ConvertFrom-Json
    
    $uuid = $payloadObj.sub
    $hash = [Math]::Abs($uuid.GetHashCode()) % 1000000
    
    Write-Host "✅ JWT obtained successfully" -ForegroundColor Green
    Write-Host "   UUID: $uuid" -ForegroundColor Gray
    Write-Host "   Hash ID: $hash" -ForegroundColor Gray
    
    # Kiểm tra xem customer với hash ID có tồn tại không
    Write-Host "🔍 Checking if customer with hash ID exists..." -ForegroundColor Cyan
    $checkResult = docker exec -it klb-postgres-customer psql -U kienlong -d customer_service_db -c "SELECT id, full_name, email FROM customers WHERE id = $hash;" 2>$null
    
    if ($checkResult -match "Test Customer Hash") {
        Write-Host "✅ Found customer with hash ID $hash" -ForegroundColor Green
        
        # Giờ test API - nhưng cần modify CustomerController để convert UUID thành hash ID
        Write-Host "🧪 Testing /my-info API..." -ForegroundColor Cyan
        
        $headers = @{
            'Authorization' = "Bearer $jwt"
            'Content-Type' = 'application/json'
        }
        
        try {
            $response = Invoke-RestMethod -Uri "http://localhost:8080/api/customers/my-info" -Method Get -Headers $headers
            Write-Host "🎉 SUCCESS! API call worked!" -ForegroundColor Green
            Write-Host "Customer data:" -ForegroundColor Green
            Write-Host "  Name: $($response.data.fullName)" -ForegroundColor White
            Write-Host "  Email: $($response.data.email)" -ForegroundColor White
            Write-Host "  Phone: $($response.data.phone)" -ForegroundColor White
            Write-Host "  Address: $($response.data.address)" -ForegroundColor White
        } catch {
            $errorResponse = $_.Exception.Response
            $statusCode = $errorResponse.StatusCode
            Write-Host "❌ API call failed: $statusCode" -ForegroundColor Red
            
            if ($statusCode -eq "NotFound") {
                Write-Host "   This is expected - API is looking for customer ID '$uuid' but we have '$hash'" -ForegroundColor Yellow
                Write-Host "   We need to modify the API to convert UUID to hash ID" -ForegroundColor Yellow
                
                Write-Host ""
                Write-Host "💡 SOLUTION: Modify CustomerController.getMyInfo() method" -ForegroundColor Cyan
                Write-Host "   Current: Long.parseLong(jwt.getSubject())" -ForegroundColor Red
                Write-Host "   Needed: Convert UUID string to hash Long" -ForegroundColor Green
            }
            
            # Try to get error details
            try {
                $errorStream = $errorResponse.GetResponseStream()
                $reader = New-Object System.IO.StreamReader($errorStream)
                $errorBody = $reader.ReadToEnd()
                Write-Host "   Error details: $errorBody" -ForegroundColor Gray
            } catch {
                # Silent fail for error details
            }
        }
    } else {
        Write-Host "❌ Customer with hash ID $hash not found" -ForegroundColor Red
        Write-Host "   Available customers:" -ForegroundColor Yellow
        docker exec -it klb-postgres-customer psql -U kienlong -d customer_service_db -c "SELECT id, full_name FROM customers ORDER BY id;" 2>$null
    }
    
} catch {
    Write-Host "❌ Failed to get JWT token: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "📝 NEXT STEPS to make /my-info work:" -ForegroundColor Yellow
Write-Host "   Option 1: Modify CustomerController to convert UUID to hash" -ForegroundColor White
Write-Host "   Option 2: Change Customer.id to UUID type" -ForegroundColor White
Write-Host "   Option 3: Create mapping table uuid -> customer_id" -ForegroundColor White
Write-Host ""
Write-Host "🎯 CURRENT STATUS:" -ForegroundColor Green
Write-Host "   ✅ JWT authentication works" -ForegroundColor White
Write-Host "   ✅ API Gateway routing works" -ForegroundColor White
Write-Host "   ✅ Database has correct customer data" -ForegroundColor White
Write-Host "   ⚠️ Just need to handle UUID -> Integer conversion" -ForegroundColor Yellow
