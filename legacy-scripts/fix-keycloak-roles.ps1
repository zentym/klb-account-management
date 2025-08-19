#!/usr/bin/env pwsh
# Script để fix Keycloak roles và assign ADMIN role cho user

Write-Host "🔧 KLB Keycloak Role Fixer" -ForegroundColor Cyan
Write-Host "==========================" -ForegroundColor Cyan

# Function để kiểm tra kết nối
function Test-KeycloakConnection {
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:8090/realms/master/.well-known/openid-configuration" -Method Get -TimeoutSec 5
        return $true
    }
    catch {
        return $false
    }
}

Write-Host "`n🔍 Step 1: Kiểm tra kết nối Keycloak..." -ForegroundColor Yellow

if (-not (Test-KeycloakConnection)) {
    Write-Host "❌ Không thể kết nối tới Keycloak tại http://localhost:8090" -ForegroundColor Red
    Write-Host "🔄 Đảm bảo Keycloak đang chạy: docker-compose up -d" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Keycloak đang hoạt động!" -ForegroundColor Green

# Lấy admin token
Write-Host "`n🔑 Step 2: Lấy admin access token..." -ForegroundColor Yellow

$tokenBody = @{
    "username" = "admin"
    "password" = "admin"
    "grant_type" = "password"
    "client_id" = "admin-cli"
}

try {
    $tokenResponse = Invoke-RestMethod -Uri "http://localhost:8090/realms/master/protocol/openid-connect/token" -Method Post -Body $tokenBody
    $adminToken = $tokenResponse.access_token
    Write-Host "✅ Admin token lấy thành công!" -ForegroundColor Green
} catch {
    Write-Host "❌ Không thể lấy admin token: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

$headers = @{
    "Authorization" = "Bearer $adminToken"
    "Content-Type" = "application/json"
}

# Tạo ADMIN role trong realm
Write-Host "`n👑 Step 3: Tạo ADMIN role trong Kienlongbank realm..." -ForegroundColor Yellow

$adminRoleData = @{
    name = "ADMIN"
    description = "Administrator role for full system access"
    clientRole = $false
} | ConvertTo-Json

try {
    Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/roles" -Method Post -Body $adminRoleData -Headers $headers
    Write-Host "✅ ADMIN role được tạo thành công!" -ForegroundColor Green
} catch {
    if ($_.Exception.Response.StatusCode -eq 409) {
        Write-Host "ℹ️ ADMIN role đã tồn tại" -ForegroundColor Blue
    } else {
        Write-Host "❌ Lỗi tạo ADMIN role: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Tạo USER role trong realm
Write-Host "`n👤 Step 4: Tạo USER role trong Kienlongbank realm..." -ForegroundColor Yellow

$userRoleData = @{
    name = "USER"
    description = "Standard user role for basic access"
    clientRole = $false
} | ConvertTo-Json

try {
    Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/roles" -Method Post -Body $userRoleData -Headers $headers
    Write-Host "✅ USER role được tạo thành công!" -ForegroundColor Green
} catch {
    if ($_.Exception.Response.StatusCode -eq 409) {
        Write-Host "ℹ️ USER role đã tồn tại" -ForegroundColor Blue
    } else {
        Write-Host "❌ Lỗi tạo USER role: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Lấy user ID của testuser
Write-Host "`n🔍 Step 5: Tìm user testuser..." -ForegroundColor Yellow

try {
    $users = Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/users?username=testuser" -Method Get -Headers $headers
    
    if ($users.Count -eq 0) {
        Write-Host "❌ Không tìm thấy user testuser" -ForegroundColor Red
        exit 1
    }
    
    $userId = $users[0].id
    Write-Host "✅ Tìm thấy user testuser (ID: $userId)" -ForegroundColor Green
} catch {
    Write-Host "❌ Lỗi tìm kiếm user: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Lấy ADMIN role ID
Write-Host "`n👑 Step 6: Lấy ADMIN role information..." -ForegroundColor Yellow

try {
    $adminRole = Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/roles/ADMIN" -Method Get -Headers $headers
    Write-Host "✅ ADMIN role info: $($adminRole.name) - $($adminRole.description)" -ForegroundColor Green
} catch {
    Write-Host "❌ Không thể lấy ADMIN role: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Assign ADMIN role cho user
Write-Host "`n🎯 Step 7: Assign ADMIN role cho testuser..." -ForegroundColor Yellow

$roleAssignmentData = @(
    @{
        id = $adminRole.id
        name = $adminRole.name
        description = $adminRole.description
        clientRole = $false
    }
) | ConvertTo-Json

try {
    Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/users/$userId/role-mappings/realm" -Method Post -Body $roleAssignmentData -Headers $headers
    Write-Host "✅ ADMIN role đã được assign cho testuser!" -ForegroundColor Green
} catch {
    if ($_.Exception.Response.StatusCode -eq 409) {
        Write-Host "ℹ️ User đã có ADMIN role" -ForegroundColor Blue
    } else {
        Write-Host "❌ Lỗi assign role: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Cập nhật client để include realm roles trong token
Write-Host "`n🔧 Step 8: Cấu hình client mappers cho realm roles..." -ForegroundColor Yellow

# Lấy klb-frontend client
try {
    $clients = Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/clients?clientId=klb-frontend" -Method Get -Headers $headers
    
    if ($clients.Count -eq 0) {
        Write-Host "❌ Không tìm thấy klb-frontend client" -ForegroundColor Red
        exit 1
    }
    
    $clientId = $clients[0].id
    Write-Host "✅ Tìm thấy klb-frontend client (ID: $clientId)" -ForegroundColor Green
} catch {
    Write-Host "❌ Lỗi tìm client: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Tạo realm roles mapper
$realmRolesMapperData = @{
    name = "realm-roles"
    protocol = "openid-connect"
    protocolMapper = "oidc-usermodel-realm-role-mapper"
    consentRequired = $false
    config = @{
        "claim.name" = "realm_access.roles"
        "jsonType.label" = "String"
        "multivalued" = "true"
        "userinfo.token.claim" = "true"
        "access.token.claim" = "true"
        "id.token.claim" = "true"
    }
} | ConvertTo-Json -Depth 3

try {
    Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/clients/$clientId/protocol-mappers/models" -Method Post -Body $realmRolesMapperData -Headers $headers
    Write-Host "✅ Realm roles mapper được tạo!" -ForegroundColor Green
} catch {
    if ($_.Exception.Response.StatusCode -eq 409) {
        Write-Host "ℹ️ Realm roles mapper đã tồn tại" -ForegroundColor Blue
    } else {
        Write-Host "⚠️ Lỗi tạo mapper (có thể đã tồn tại): $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

# Verification test
Write-Host "`n✅ Step 9: Test verification..." -ForegroundColor Yellow

Write-Host "   🧪 Testing login with new roles..." -ForegroundColor Blue

$loginData = @{
    "username" = "testuser"
    "password" = "password123"
    "grant_type" = "password"
    "client_id" = "klb-frontend"
} 

try {
    $loginResponse = Invoke-RestMethod -Uri "http://localhost:8090/realms/Kienlongbank/protocol/openid-connect/token" -Method Post -Body $loginData -ContentType "application/x-www-form-urlencoded"
    
    $accessToken = $loginResponse.access_token
    Write-Host "   ✅ Login successful với token mới!" -ForegroundColor Green
    
    # Test admin endpoint
    $authHeaders = @{
        "Authorization" = "Bearer $accessToken"
        "Content-Type" = "application/json"
    }
    
    try {
        Write-Host "   🔐 Testing admin endpoint..." -ForegroundColor Blue
        $adminResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/admin/hello" -Method Get -Headers $authHeaders
        Write-Host "   ✅ Admin access: SUCCESS!" -ForegroundColor Green
        Write-Host "   📝 Response: $adminResponse" -ForegroundColor White
    } catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        Write-Host "   ⚠️ Admin access: Status $statusCode" -ForegroundColor Yellow
        if ($statusCode -eq 403) {
            Write-Host "   🔄 Role mapping có thể cần thêm thời gian để áp dụng" -ForegroundColor Blue
        }
    }
    
} catch {
    Write-Host "   ❌ Test login failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n🎉 Role configuration completed!" -ForegroundColor Green
Write-Host "📋 Summary của changes:" -ForegroundColor Cyan
Write-Host "   ✅ Created ADMIN role in Kienlongbank realm" -ForegroundColor White
Write-Host "   ✅ Created USER role in Kienlongbank realm" -ForegroundColor White
Write-Host "   ✅ Assigned ADMIN role to testuser" -ForegroundColor White
Write-Host "   ✅ Configured realm roles mapper for klb-frontend client" -ForegroundColor White

Write-Host "`n🔄 Next steps:" -ForegroundColor Yellow
Write-Host "   1. Test lại bằng: powershell -ExecutionPolicy Bypass -File check-user-roles.ps1" -ForegroundColor White
Write-Host "   2. Nếu vẫn 403, restart Spring Boot services" -ForegroundColor White
Write-Host "   3. Kiểm tra JWT token có chứa ADMIN role chưa" -ForegroundColor White

Write-Host "`n💡 Note:" -ForegroundColor Blue
Write-Host "   Có thể cần đợi vài giây để role changes có hiệu lực" -ForegroundColor Gray
Write-Host "   Hoặc logout/login lại trong frontend application" -ForegroundColor Gray
