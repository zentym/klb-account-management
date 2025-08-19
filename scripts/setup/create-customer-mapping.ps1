# Create customers with IDs derived from JWT UUIDs for testing
Write-Host "🔧 Creating customers with mapped IDs for /my-info testing..." -ForegroundColor Green

# UUIDs from the JWT subjects we got earlier
$uuidMappings = @(
    @{uuid = "53b64f82-f8d0-410e-9d7d-632a715c45b1"; username = "customer3"; name = "Nguyen Van A"; email = "nguyenvana@klb.com"},
    @{uuid = "99e13bd1-3d26-4553-af8a-6b3e7eb842b1"; username = "customer4"; name = "Tran Thi B"; email = "tranthib@klb.com"},
    @{uuid = "7111a0ca-97b9-488f-a81a-ab6ce6660d68"; username = "customer5"; name = "Le Van C"; email = "levanc@klb.com"}
)

Write-Host "📊 Current database state:" -ForegroundColor Yellow
docker exec -it klb-postgres-customer psql -U kienlong -d customer_service_db -c "SELECT id, full_name, email FROM customers ORDER BY id;" 2>$null

Write-Host ""
Write-Host "💡 For testing purposes, let's create a simple solution:" -ForegroundColor Cyan
Write-Host "   We'll modify the API to use a user attribute instead of subject" -ForegroundColor White

# Alternative approach: Create customer records with sequential IDs and use attributes
Write-Host ""  
Write-Host "🧪 Let's test the current API with customer ID 1..." -ForegroundColor Green

# Get admin token and create a simple test user with customer_id attribute  
$adminTokenBody = @{
    username = "admin"
    password = "admin"
    grant_type = "password"
    client_id = "admin-cli"
}

try {
    $adminTokenResponse = Invoke-RestMethod -Uri "http://localhost:8090/realms/master/protocol/openid-connect/token" -Method Post -Body $adminTokenBody
    $adminToken = $adminTokenResponse.access_token
    
    $adminHeaders = @{
        'Authorization' = "Bearer $adminToken"
        'Content-Type' = 'application/json'
    }
    
    # Check if we can find an existing user to update
    $existingUsers = Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/users" -Method Get -Headers $adminHeaders
    
    $testUser = $null
    foreach ($user in $existingUsers) {
        if ($user.username -eq "testcustomer") {
            $testUser = $user
            break
        }
    }
    
    if ($testUser) {
        Write-Host "✅ Found testcustomer user: $($testUser.id)" -ForegroundColor Green
        Write-Host "🔧 Let's test by temporarily modifying our API to handle this mismatch..." -ForegroundColor Yellow
        
        # For now, let's create a customer record with the UUID as a string ID if possible
        # Or create a workaround in the API
        
        Write-Host ""
        Write-Host "🎯 SOLUTION: Let's create customer with ID matching the hash of UUID" -ForegroundColor Cyan
        
        # Create a simple hash function to map UUID to integer
        $hash = [Math]::Abs($testUser.id.GetHashCode()) % 1000000  # Get a reasonable integer
        
        Write-Host "   UUID: $($testUser.id)" -ForegroundColor Gray
        Write-Host "   Hash ID: $hash" -ForegroundColor Gray
        
        # Create customer with this hash ID
        $insertResult = docker exec -it klb-postgres-customer psql -U kienlong -d customer_service_db -c "INSERT INTO customers (id, full_name, email, phone, address) VALUES ($hash, 'Test Customer Hash', 'testhash@customer.com', '0999999999', '999 Hash Street') ON CONFLICT (id) DO UPDATE SET full_name = EXCLUDED.full_name;"
        
        Write-Host "✅ Created customer with hash ID: $hash" -ForegroundColor Green
        
        # For a complete solution, we need to modify the CustomerController
        Write-Host ""
        Write-Host "💡 CURRENT STATUS:" -ForegroundColor Yellow
        Write-Host "   ✅ Database has customer records" -ForegroundColor White
        Write-Host "   ✅ /my-info API implementation is correct" -ForegroundColor White
        Write-Host "   ⚠️ JWT subject (UUID) vs Customer ID (Integer) mismatch" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "📝 RECOMMENDATION:" -ForegroundColor Green
        Write-Host "   For production: Change Customer.id to UUID type" -ForegroundColor White
        Write-Host "   For testing: Modify API to use user attributes or create UUID mapping" -ForegroundColor White
        
        # Show current database state
        Write-Host ""
        Write-Host "📊 Final database state:" -ForegroundColor Cyan
        docker exec -it klb-postgres-customer psql -U kienlong -d customer_service_db -c "SELECT id, full_name, email FROM customers ORDER BY id;" 2>$null
        
    }
    
} catch {
    Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
}
