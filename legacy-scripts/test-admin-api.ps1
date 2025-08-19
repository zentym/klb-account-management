#!/usr/bin/env pwsh
# PowerShell script để test API tạo admin

Write-Host "🔧 Testing Admin Creation API" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green

$baseUrl = "http://localhost:8080/api/auth"

# Function to make HTTP requests
function Invoke-ApiRequest {
    param(
        [string]$Method,
        [string]$Url,
        [hashtable]$Body = $null,
        [string]$Description
    )
    
    Write-Host "`n📡 $Description" -ForegroundColor Yellow
    Write-Host "   $Method $Url" -ForegroundColor Cyan
    
    try {
        $headers = @{ "Content-Type" = "application/json" }
        
        if ($Body) {
            $jsonBody = $Body | ConvertTo-Json
            Write-Host "   Body: $jsonBody" -ForegroundColor Gray
            $response = Invoke-RestMethod -Uri $Url -Method $Method -Headers $headers -Body $jsonBody
        }
        else {
            $response = Invoke-RestMethod -Uri $Url -Method $Method -Headers $headers
        }
        
        Write-Host "   ✅ Success:" -ForegroundColor Green
        Write-Host "   $($response | ConvertTo-Json -Depth 3)" -ForegroundColor White
        return $response
    }
    catch {
        Write-Host "   ❌ Error: $($_.Exception.Message)" -ForegroundColor Red
        if ($_.Exception.Response) {
            $errorContent = $_.Exception.Response.Content.ReadAsStringAsync().Result
            Write-Host "   Error details: $errorContent" -ForegroundColor Red
        }
        return $null
    }
}

# Wait for server to start (optional)
Write-Host "`n⏳ Waiting for server to start (you can run this script when server is ready)..." -ForegroundColor Magenta
Start-Sleep -Seconds 2

# Test 1: Check admin status before creating any admin
Invoke-ApiRequest -Method "GET" -Url "$baseUrl/admin-status" -Description "Kiểm tra trạng thái admin ban đầu"

# Test 2: Create first admin user
$adminData = @{
    username = "admin"
    password = "admin123"
}

Invoke-ApiRequest -Method "POST" -Url "$baseUrl/register-admin" -Body $adminData -Description "Tạo admin user đầu tiên"

# Test 3: Check admin status after creating admin
Invoke-ApiRequest -Method "GET" -Url "$baseUrl/admin-status" -Description "Kiểm tra trạng thái admin sau khi tạo"

# Test 4: Try to create another admin with same username (should fail)
Invoke-ApiRequest -Method "POST" -Url "$baseUrl/register-admin" -Body $adminData -Description "Thử tạo admin với username trùng (nên thất bại)"

# Test 5: Create second admin with different username
$admin2Data = @{
    username = "admin2"
    password = "admin456"
}

Invoke-ApiRequest -Method "POST" -Url "$baseUrl/register-admin" -Body $admin2Data -Description "Tạo admin user thứ hai"

# Test 6: Final admin status check
Invoke-ApiRequest -Method "GET" -Url "$baseUrl/admin-status" -Description "Kiểm tra trạng thái admin cuối cùng"

# Test 7: Test login with admin credentials
$loginData = @{
    username = "admin"
    password = "admin123"
}

$loginResponse = Invoke-ApiRequest -Method "POST" -Url "$baseUrl/login" -Body $loginData -Description "Đăng nhập với tài khoản admin"

if ($loginResponse -and $loginResponse.token) {
    Write-Host "`n🎉 Admin login successful! Token received." -ForegroundColor Green
    Write-Host "   Token: $($loginResponse.token)" -ForegroundColor Cyan
}
else {
    Write-Host "`n❌ Admin login failed." -ForegroundColor Red
}

Write-Host "`n🏁 Test completed!" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green
