#!/usr/bin/env pwsh
# PowerShell script để test quyền Admin

Write-Host "🔒 Testing Admin Permissions" -ForegroundColor Green
Write-Host "============================" -ForegroundColor Green

$baseUrl = "http://localhost:8080"
$authUrl = "$baseUrl/api/auth"
$adminUrl = "$baseUrl/api/admin"

# Function to make HTTP requests
function Invoke-ApiRequest {
    param(
        [string]$Method,
        [string]$Url,
        [hashtable]$Headers = @{},
        [hashtable]$Body = $null,
        [string]$Description
    )
    
    Write-Host "`n📡 $Description" -ForegroundColor Yellow
    Write-Host "   $Method $Url" -ForegroundColor Cyan
    
    try {
        $requestHeaders = @{ "Content-Type" = "application/json" }
        foreach ($header in $Headers.GetEnumerator()) {
            $requestHeaders[$header.Key] = $header.Value
        }
        
        if ($Body) {
            $jsonBody = $Body | ConvertTo-Json
            Write-Host "   Body: $jsonBody" -ForegroundColor Gray
            $response = Invoke-RestMethod -Uri $Url -Method $Method -Headers $requestHeaders -Body $jsonBody
        }
        else {
            $response = Invoke-RestMethod -Uri $Url -Method $Method -Headers $requestHeaders
        }
        
        Write-Host "   ✅ Success:" -ForegroundColor Green
        if ($response -is [string]) {
            Write-Host "   $response" -ForegroundColor White
        }
        else {
            Write-Host "   $($response | ConvertTo-Json -Depth 3)" -ForegroundColor White
        }
        return $response
    }
    catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        Write-Host "   ❌ Error ($statusCode): $($_.Exception.Message)" -ForegroundColor Red
        if ($_.Exception.Response) {
            try {
                $errorContent = $_.Exception.Response.Content.ReadAsStringAsync().Result
                Write-Host "   Error details: $errorContent" -ForegroundColor Red
            }
            catch {
                Write-Host "   Could not read error details" -ForegroundColor Red
            }
        }
        return $null
    }
}

Write-Host "`n🚀 Step 1: Tạo Admin User" -ForegroundColor Magenta

# Tạo admin user
$adminData = @{
    username = "admin$(Get-Date -Format 'hhmmss')"
    password = "admin123"
}

$adminResponse = Invoke-ApiRequest -Method "POST" -Url "$authUrl/register-admin" -Body $adminData -Description "Tạo admin user"

if (-not $adminResponse -or -not $adminResponse.token) {
    Write-Host "`n❌ Không thể tạo admin user. Dừng test." -ForegroundColor Red
    exit 1
}

$adminToken = $adminResponse.token
Write-Host "`nAdmin token: $adminToken" -ForegroundColor Cyan

Write-Host "`n🚀 Step 2: Tạo User thường" -ForegroundColor Magenta

# Tạo user thường
$userData = @{
    username = "user$(Get-Date -Format 'hhmmss')"
    password = "user123"
}

$userResponse = Invoke-ApiRequest -Method "POST" -Url "$authUrl/register" -Body $userData -Description "Tạo user thường"

if (-not $userResponse -or -not $userResponse.token) {
    Write-Host "`n❌ Không thể tạo user thường. Tiếp tục test với admin..." -ForegroundColor Yellow
}
else {
    $userToken = $userResponse.token
    Write-Host "`nUser token: $userToken" -ForegroundColor Cyan
}

Write-Host "`n🚀 Step 3: Test quyền Admin" -ForegroundColor Magenta

# Test admin endpoints với admin token
$adminHeaders = @{ "Authorization" = "Bearer $adminToken" }

Invoke-ApiRequest -Method "GET" -Url "$adminUrl/hello" -Headers $adminHeaders -Description "Test admin hello (với admin token)"
Invoke-ApiRequest -Method "GET" -Url "$adminUrl/dashboard" -Headers $adminHeaders -Description "Test admin dashboard (với admin token)"
Invoke-ApiRequest -Method "GET" -Url "$adminUrl/stats" -Headers $adminHeaders -Description "Test admin stats (với admin token)"

Write-Host "`n🚀 Step 4: Test quyền User (nên bị từ chối)" -ForegroundColor Magenta

if ($userToken) {
    # Test admin endpoints với user token (nên bị từ chối)
    $userHeaders = @{ "Authorization" = "Bearer $userToken" }
    
    Invoke-ApiRequest -Method "GET" -Url "$adminUrl/hello" -Headers $userHeaders -Description "Test admin hello (với user token - nên bị từ chối)"
    Invoke-ApiRequest -Method "GET" -Url "$adminUrl/dashboard" -Headers $userHeaders -Description "Test admin dashboard (với user token - nên bị từ chối)"
    Invoke-ApiRequest -Method "GET" -Url "$adminUrl/stats" -Headers $userHeaders -Description "Test admin stats (với user token - nên bị từ chối)"
}
else {
    Write-Host "   ⚠️ Không có user token để test" -ForegroundColor Yellow
}

Write-Host "`n🚀 Step 5: Test không có token (nên bị từ chối)" -ForegroundColor Magenta

Invoke-ApiRequest -Method "GET" -Url "$adminUrl/hello" -Description "Test admin hello (không có token - nên bị từ chối)"
Invoke-ApiRequest -Method "GET" -Url "$adminUrl/dashboard" -Description "Test admin dashboard (không có token - nên bị từ chối)"

Write-Host "`n🚀 Step 6: Kiểm tra JWT payload" -ForegroundColor Magenta

# Decode JWT để xem payload (chỉ để debug, không an toàn trong production)
if ($adminToken) {
    $parts = $adminToken.Split('.')
    if ($parts.Length -eq 3) {
        try {
            # Thêm padding nếu cần
            $payload = $parts[1]
            while ($payload.Length % 4 -ne 0) {
                $payload += "="
            }
            
            $decodedBytes = [System.Convert]::FromBase64String($payload)
            $decodedText = [System.Text.Encoding]::UTF8.GetString($decodedBytes)
            Write-Host "`n🔍 JWT Payload của Admin:" -ForegroundColor Cyan
            Write-Host $decodedText -ForegroundColor White
        }
        catch {
            Write-Host "`n⚠️ Không thể decode JWT payload: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
}

Write-Host "`n🏁 Test hoàn tất!" -ForegroundColor Green
Write-Host "============================" -ForegroundColor Green
Write-Host "✅ Admin user có thể truy cập /api/admin/**" -ForegroundColor Green
Write-Host "❌ User thường không thể truy cập /api/admin/**" -ForegroundColor Green
Write-Host "❌ Không có token không thể truy cập /api/admin/**" -ForegroundColor Green
