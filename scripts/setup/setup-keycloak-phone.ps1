#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Setup Keycloak với Phone Number Authentication
    
.DESCRIPTION
    Script cập nhật Keycloak để hỗ trợ đăng nhập bằng số điện thoại thay vì username
    
.EXAMPLE
    .\setup-keycloak-phone.ps1
#>

Write-Host "📱 Cập nhật Keycloak cho Phone Number Authentication..." -ForegroundColor Cyan
Write-Host ""

# Wait for Keycloak to be ready
Write-Host "⏳ Chờ Keycloak sẵn sàng..." -ForegroundColor Yellow
do {
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8090/realms/master/.well-known/openid-configuration" -UseBasicParsing -TimeoutSec 5
        if ($response.StatusCode -eq 200) {
            Write-Host "✅ Keycloak đã sẵn sàng!" -ForegroundColor Green
            break
        }
    } catch {
        Write-Host "⏳ Đang chờ Keycloak..." -ForegroundColor Yellow
        Start-Sleep 2
    }
} while ($true)

# Get admin token
Write-Host "🔑 Lấy admin token..." -ForegroundColor Yellow
$tokenResponse = @{
    Uri = "http://localhost:8090/realms/master/protocol/openid-connect/token"
    Method = "Post"
    Headers = @{ "Content-Type" = "application/x-www-form-urlencoded" }
    Body = "username=admin&password=admin&grant_type=password&client_id=admin-cli"
}

try {
    $response = Invoke-RestMethod @tokenResponse
    $adminToken = $response.access_token
    
    if (-not $adminToken) {
        throw "No access token received"
    }
    
    Write-Host "✅ Đã lấy admin token" -ForegroundColor Green
} catch {
    Write-Host "❌ Không thể lấy admin token: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "💡 Hãy đảm bảo Keycloak đang chạy và admin credentials là 'admin/admin'" -ForegroundColor Yellow
    exit 1
}

$headers = @{
    "Authorization" = "Bearer $adminToken"
    "Content-Type" = "application/json"
}

# Create Kienlongbank realm if not exists
Write-Host "🏗️ Tạo Kienlongbank realm..." -ForegroundColor Yellow
$realmData = @{
    realm = "Kienlongbank"
    enabled = $true
    displayName = "Kien Long Bank - Phone Authentication"
    accessCodeLifespan = 300
    accessTokenLifespan = 3600
    refreshTokenMaxReuse = 0
    ssoSessionIdleTimeout = 1800
    ssoSessionMaxLifespan = 36000
} | ConvertTo-Json

try {
    Invoke-RestMethod -Uri "http://localhost:8090/admin/realms" -Method Post -Body $realmData -Headers $headers
    Write-Host "✅ Realm đã tạo" -ForegroundColor Green
} catch {
    if ($_.Exception.Response.StatusCode -eq 409) {
        Write-Host "ℹ️ Realm đã tồn tại" -ForegroundColor Blue
    } else {
        Write-Host "❌ Lỗi tạo realm: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Create klb-frontend client
Write-Host "🔧 Tạo klb-frontend client..." -ForegroundColor Yellow
$clientData = @{
    clientId = "klb-frontend"
    name = "KLB Frontend Application - Phone Auth"
    enabled = $true
    publicClient = $true
    directAccessGrantsEnabled = $true
    standardFlowEnabled = $true
    implicitFlowEnabled = $false
    serviceAccountsEnabled = $false
    redirectUris = @("http://localhost:3000/*")
    webOrigins = @("http://localhost:3000")
    protocol = "openid-connect"
    attributes = @{
        "login_theme" = "phone-login"
    }
} | ConvertTo-Json -Depth 3

try {
    Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/clients" -Method Post -Body $clientData -Headers $headers
    Write-Host "✅ Frontend client đã tạo" -ForegroundColor Green
} catch {
    if ($_.Exception.Response.StatusCode -eq 409) {
        Write-Host "ℹ️ Frontend client đã tồn tại" -ForegroundColor Blue
    } else {
        Write-Host "❌ Lỗi tạo frontend client: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Create klb-backend-api client (confidential)
Write-Host "🔧 Tạo klb-backend-api client..." -ForegroundColor Yellow
$backendClientData = @{
    clientId = "klb-backend-api"
    name = "KLB Backend API - Phone Auth"
    enabled = $true
    publicClient = $false
    directAccessGrantsEnabled = $true
    standardFlowEnabled = $true
    implicitFlowEnabled = $false
    serviceAccountsEnabled = $true
    bearerOnly = $false
    protocol = "openid-connect"
    attributes = @{
        "access.token.lifespan" = "3600"
        "phone.number.required" = "true"
    }
} | ConvertTo-Json -Depth 3

try {
    Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/clients" -Method Post -Body $backendClientData -Headers $headers
    Write-Host "✅ Backend client đã tạo" -ForegroundColor Green
} catch {
    if ($_.Exception.Response.StatusCode -eq 409) {
        Write-Host "ℹ️ Backend client đã tồn tại" -ForegroundColor Blue
    } else {
        Write-Host "❌ Lỗi tạo backend client: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Create realm roles
Write-Host "🔧 Tạo realm roles..." -ForegroundColor Yellow
$roles = @("USER", "ADMIN")

foreach ($roleName in $roles) {
    $roleData = @{
        name = $roleName
        description = "Role for $roleName access - Phone Auth"
    } | ConvertTo-Json
    
    try {
        Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/roles" -Method Post -Body $roleData -Headers $headers
        Write-Host "✅ Role '$roleName' đã tạo" -ForegroundColor Green
    } catch {
        if ($_.Exception.Response.StatusCode -eq 409) {
            Write-Host "ℹ️ Role '$roleName' đã tồn tại" -ForegroundColor Blue
        } else {
            Write-Host "❌ Lỗi tạo role '$roleName': $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# Delete existing phone-based users if they exist
Write-Host "🧹 Xóa users cũ nếu có..." -ForegroundColor Yellow
$phoneUsers = @("0901234567", "0987654321")
foreach ($phoneUser in $phoneUsers) {
    try {
        $existingUsers = Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/users?username=$phoneUser" -Headers $headers
        if ($existingUsers.Count -gt 0) {
            $userId = $existingUsers[0].id
            Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/users/$userId" -Method Delete -Headers $headers
            Write-Host "🗑️ Đã xóa user: $phoneUser" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "ℹ️ User $phoneUser không tồn tại" -ForegroundColor Blue
    }
}

# Create phone-based admin user
Write-Host "👤 Tạo Admin user với SĐT: 0901234567..." -ForegroundColor Yellow
$adminUserData = @{
    username = "0901234567"
    email = "admin@kienlongbank.com"
    firstName = "Admin"
    lastName = "User"
    enabled = $true
    attributes = @{
        phoneNumber = @("0901234567")
        userType = @("ADMIN")
    }
    credentials = @(
        @{
            type = "password"
            value = "admin123"
            temporary = $false
        }
    )
} | ConvertTo-Json -Depth 3

try {
    Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/users" -Method Post -Body $adminUserData -Headers $headers
    Write-Host "✅ Admin user đã tạo: 0901234567 / admin123" -ForegroundColor Green
} catch {
    if ($_.Exception.Response.StatusCode -eq 409) {
        Write-Host "ℹ️ Admin user đã tồn tại" -ForegroundColor Blue
    } else {
        Write-Host "❌ Lỗi tạo admin user: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Create phone-based regular user
Write-Host "👤 Tạo Regular user với SĐT: 0987654321..." -ForegroundColor Yellow
$regularUserData = @{
    username = "0987654321"
    email = "user@kienlongbank.com"
    firstName = "Regular"
    lastName = "User"
    enabled = $true
    attributes = @{
        phoneNumber = @("0987654321")
        userType = @("USER")
    }
    credentials = @(
        @{
            type = "password"
            value = "password123"
            temporary = $false
        }
    )
} | ConvertTo-Json -Depth 3

try {
    Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/users" -Method Post -Body $regularUserData -Headers $headers
    Write-Host "✅ Regular user đã tạo: 0987654321 / password123" -ForegroundColor Green
} catch {
    if ($_.Exception.Response.StatusCode -eq 409) {
        Write-Host "ℹ️ Regular user đã tồn tại" -ForegroundColor Blue
    } else {
        Write-Host "❌ Lỗi tạo regular user: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Assign ADMIN role to admin user
Write-Host "🔐 Gán ADMIN role cho admin user..." -ForegroundColor Yellow
try {
    # Get admin user ID
    $adminUsers = Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/users?username=0901234567" -Headers $headers
    if ($adminUsers.Count -gt 0) {
        $adminUserId = $adminUsers[0].id
        
        # Get ADMIN role
        $adminRole = Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/roles/ADMIN" -Headers $headers
        
        # Check if user already has ADMIN role
        $currentRoles = Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/users/$adminUserId/role-mappings/realm" -Headers $headers
        $hasAdminRole = $currentRoles | Where-Object { $_.name -eq "ADMIN" }
        
        if ($hasAdminRole) {
            Write-Host "✅ ADMIN role đã được gán cho 0901234567" -ForegroundColor Green
        } else {
            # Use correct format for role assignment (like in setup-keycloak.ps1)
            $roleAssignment = "[{`"id`":`"$($adminRole.id)`",`"name`":`"ADMIN`",`"description`":`"Role for ADMIN access - Phone Auth`",`"composite`":false}]"
            
            $response = Invoke-WebRequest -Uri "http://localhost:8090/admin/realms/Kienlongbank/users/$adminUserId/role-mappings/realm" -Method Post -Body $roleAssignment -Headers $headers -UseBasicParsing
            
            if ($response.StatusCode -eq 204 -or $response.StatusCode -eq 200) {
                Write-Host "✅ ADMIN role đã gán cho 0901234567" -ForegroundColor Green
            } else {
                Write-Host "⚠️ Unexpected response code: $($response.StatusCode)" -ForegroundColor Yellow
            }
        }
    }
} catch {
    Write-Host "⚠️ Không thể gán ADMIN role: $($_.Exception.Message)" -ForegroundColor Yellow
    # Try alternative approach
    Write-Host "🔄 Thử phương pháp gán role khác..." -ForegroundColor Yellow
    try {
        Start-Sleep -Seconds 1
        $adminUsers = Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/users?username=0901234567" -Headers $headers
        if ($adminUsers.Count -gt 0) {
            $adminUserId = $adminUsers[0].id
            $adminRole = Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/roles/ADMIN" -Headers $headers
            
            # Simple role assignment with minimal data
            $simpleRoleData = @(
                @{
                    id = $adminRole.id
                    name = "ADMIN"
                }
            ) | ConvertTo-Json -Depth 2 -Compress
            
            Invoke-WebRequest -Uri "http://localhost:8090/admin/realms/Kienlongbank/users/$adminUserId/role-mappings/realm" -Method Post -Body $simpleRoleData -Headers $headers -UseBasicParsing
            Write-Host "✅ ADMIN role đã gán qua phương pháp thay thế" -ForegroundColor Green
        }
    } catch {
        Write-Host "❌ Lỗi gán ADMIN role qua phương pháp thay thế: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Assign USER role to regular user
Write-Host "🔐 Gán USER role cho regular user..." -ForegroundColor Yellow
try {
    # Get regular user ID
    $regularUsers = Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/users?username=0987654321" -Headers $headers
    if ($regularUsers.Count -gt 0) {
        $regularUserId = $regularUsers[0].id
        
        # Get USER role
        $userRole = Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/roles/USER" -Headers $headers
        
        # Check if user already has USER role
        $currentRoles = Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/users/$regularUserId/role-mappings/realm" -Headers $headers
        $hasUserRole = $currentRoles | Where-Object { $_.name -eq "USER" }
        
        if ($hasUserRole) {
            Write-Host "✅ USER role đã được gán cho 0987654321" -ForegroundColor Green
        } else {
            # Use correct format for role assignment (like in setup-keycloak.ps1)
            $roleAssignment = "[{`"id`":`"$($userRole.id)`",`"name`":`"USER`",`"description`":`"Role for USER access - Phone Auth`",`"composite`":false}]"
            
            $response = Invoke-WebRequest -Uri "http://localhost:8090/admin/realms/Kienlongbank/users/$regularUserId/role-mappings/realm" -Method Post -Body $roleAssignment -Headers $headers -UseBasicParsing
            
            if ($response.StatusCode -eq 204 -or $response.StatusCode -eq 200) {
                Write-Host "✅ USER role đã gán cho 0987654321" -ForegroundColor Green
            } else {
                Write-Host "⚠️ Unexpected response code: $($response.StatusCode)" -ForegroundColor Yellow
            }
        }
    }
} catch {
    Write-Host "⚠️ Không thể gán USER role: $($_.Exception.Message)" -ForegroundColor Yellow
    # Try alternative approach
    Write-Host "🔄 Thử phương pháp gán role khác..." -ForegroundColor Yellow
    try {
        Start-Sleep -Seconds 1
        $regularUsers = Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/users?username=0987654321" -Headers $headers
        if ($regularUsers.Count -gt 0) {
            $regularUserId = $regularUsers[0].id
            $userRole = Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/roles/USER" -Headers $headers
            
            # Simple role assignment with minimal data
            $simpleRoleData = @(
                @{
                    id = $userRole.id
                    name = "USER"
                }
            ) | ConvertTo-Json -Depth 2 -Compress
            
            Invoke-WebRequest -Uri "http://localhost:8090/admin/realms/Kienlongbank/users/$regularUserId/role-mappings/realm" -Method Post -Body $simpleRoleData -Headers $headers -UseBasicParsing
            Write-Host "✅ USER role đã gán qua phương pháp thay thế" -ForegroundColor Green
        }
    } catch {
        Write-Host "❌ Lỗi gán USER role qua phương pháp thay thế: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Verify users and roles
Write-Host "🔍 Xác minh cấu hình..." -ForegroundColor Yellow
try {
    # Check admin user
    $adminUsers = Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/users?username=0901234567" -Headers $headers
    if ($adminUsers.Count -gt 0) {
        $adminUserId = $adminUsers[0].id
        $adminRoles = Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/users/$adminUserId/role-mappings/realm" -Headers $headers
        $hasAdminRole = $adminRoles | Where-Object { $_.name -eq "ADMIN" }
        
        if ($hasAdminRole) {
            Write-Host "✅ Admin user (0901234567) có ADMIN role" -ForegroundColor Green
        } else {
            Write-Host "⚠️ Admin user thiếu ADMIN role" -ForegroundColor Yellow
        }
    }
    
    # Check regular user
    $regularUsers = Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/users?username=0987654321" -Headers $headers
    if ($regularUsers.Count -gt 0) {
        $regularUserId = $regularUsers[0].id
        $regularRoles = Invoke-RestMethod -Uri "http://localhost:8090/admin/realms/Kienlongbank/users/$regularUserId/role-mappings/realm" -Headers $headers
        $hasUserRole = $regularRoles | Where-Object { $_.name -eq "USER" }
        
        if ($hasUserRole) {
            Write-Host "✅ Regular user (0987654321) có USER role" -ForegroundColor Green
        } else {
            Write-Host "⚠️ Regular user thiếu USER role" -ForegroundColor Yellow
        }
    }
} catch {
    Write-Host "⚠️ Không thể xác minh role assignment: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host ""
# Setup customer data in backend services
Write-Host "📊 Thiết lập thông tin khách hàng..." -ForegroundColor Yellow

# Wait for services to be ready
Write-Host "⏳ Chờ services sẵn sàng..." -ForegroundColor Yellow
$servicesReady = $false
$maxRetries = 30
$retryCount = 0

while (-not $servicesReady -and $retryCount -lt $maxRetries) {
    try {
        # Check main service
        $mainResponse = Invoke-WebRequest -Uri "http://localhost:8080/actuator/health" -UseBasicParsing -TimeoutSec 3
        # Check customer service  
        $customerResponse = Invoke-WebRequest -Uri "http://localhost:8082/actuator/health" -UseBasicParsing -TimeoutSec 3
        
        if ($mainResponse.StatusCode -eq 200 -and $customerResponse.StatusCode -eq 200) {
            $servicesReady = $true
            Write-Host "✅ Tất cả services đã sẵn sàng!" -ForegroundColor Green
        }
    } catch {
        $retryCount++
        Write-Host "⏳ Đang chờ services... ($retryCount/$maxRetries)" -ForegroundColor Yellow
        Start-Sleep 3
    }
}

if (-not $servicesReady) {
    Write-Host "⚠️ Services chưa sẵn sàng, bỏ qua setup customer data" -ForegroundColor Yellow
} else {
    # Get authentication token for API calls
    Write-Host "🔐 Lấy token để gọi API..." -ForegroundColor Yellow
    try {
        $tokenData = @{
            username = "0901234567"
            password = "admin123"
            grant_type = "password"
            client_id = "klb-frontend"
        }
        
        $tokenBody = ($tokenData.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join "&"
        $tokenResponse = Invoke-RestMethod -Uri "http://localhost:8090/realms/Kienlongbank/protocol/openid-connect/token" -Method Post -Body $tokenBody -ContentType "application/x-www-form-urlencoded"
        
        $accessToken = $tokenResponse.access_token
        $apiHeaders = @{
            "Authorization" = "Bearer $accessToken"
            "Content-Type" = "application/json"
        }
        
        Write-Host "✅ Đã lấy API token" -ForegroundColor Green
        
        # Create customer data
        Write-Host "👥 Tạo thông tin khách hàng..." -ForegroundColor Yellow
        
        # Admin customer
        $adminCustomer = @{
            firstName = "Nguyễn"
            lastName = "Văn Admin"
            email = "admin@kienlongbank.com"
            phoneNumber = "0901234567"
            address = "123 Đường Nguyễn Huệ, Q1, TP.HCM"
            dateOfBirth = "1985-01-15"
            identityNumber = "123456789"
        } | ConvertTo-Json
        
        try {
            $adminCustomerResponse = Invoke-RestMethod -Uri "http://localhost:8082/api/customers" -Method Post -Body $adminCustomer -Headers $apiHeaders
            Write-Host "✅ Đã tạo thông tin khách hàng cho Admin (ID: $($adminCustomerResponse.id))" -ForegroundColor Green
        } catch {
            if ($_.Exception.Response.StatusCode -eq 409) {
                Write-Host "ℹ️ Khách hàng Admin đã tồn tại" -ForegroundColor Blue
            } else {
                Write-Host "⚠️ Lỗi tạo khách hàng Admin: $($_.Exception.Message)" -ForegroundColor Yellow
            }
        }
        
        # Regular customer
        $regularCustomer = @{
            firstName = "Trần"
            lastName = "Thị User"
            email = "user@kienlongbank.com"
            phoneNumber = "0987654321"
            address = "456 Đường Lê Lợi, Q3, TP.HCM"
            dateOfBirth = "1990-05-20"
            identityNumber = "987654321"
        } | ConvertTo-Json
        
        try {
            $regularCustomerResponse = Invoke-RestMethod -Uri "http://localhost:8082/api/customers" -Method Post -Body $regularCustomer -Headers $apiHeaders
            Write-Host "✅ Đã tạo thông tin khách hàng cho User (ID: $($regularCustomerResponse.id))" -ForegroundColor Green
        } catch {
            if ($_.Exception.Response.StatusCode -eq 409) {
                Write-Host "ℹ️ Khách hàng User đã tồn tại" -ForegroundColor Blue
            } else {
                Write-Host "⚠️ Lỗi tạo khách hàng User: $($_.Exception.Message)" -ForegroundColor Yellow
            }
        }
        
        # Create sample accounts
        Write-Host "🏦 Tạo tài khoản ngân hàng mẫu..." -ForegroundColor Yellow
        
        # Admin account
        $adminAccount = @{
            accountNumber = "001234567890"
            accountType = "SAVINGS"
            balance = 10000000
            customerId = if ($adminCustomerResponse.id) { $adminCustomerResponse.id } else { 1 }
        } | ConvertTo-Json
        
        try {
            $adminAccountResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/accounts" -Method Post -Body $adminAccount -Headers $apiHeaders
            Write-Host "✅ Đã tạo tài khoản cho Admin: 001234567890" -ForegroundColor Green
        } catch {
            if ($_.Exception.Response.StatusCode -eq 409) {
                Write-Host "ℹ️ Tài khoản Admin đã tồn tại" -ForegroundColor Blue
            } else {
                Write-Host "⚠️ Lỗi tạo tài khoản Admin: $($_.Exception.Message)" -ForegroundColor Yellow
            }
        }
        
        # Regular user account
        $regularAccount = @{
            accountNumber = "009876543210"
            accountType = "CHECKING"
            balance = 5000000
            customerId = if ($regularCustomerResponse.id) { $regularCustomerResponse.id } else { 2 }
        } | ConvertTo-Json
        
        try {
            $regularAccountResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/accounts" -Method Post -Body $regularAccount -Headers $apiHeaders
            Write-Host "✅ Đã tạo tài khoản cho User: 009876543210" -ForegroundColor Green
        } catch {
            if ($_.Exception.Response.StatusCode -eq 409) {
                Write-Host "ℹ️ Tài khoản User đã tồn tại" -ForegroundColor Blue
            } else {
                Write-Host "⚠️ Lỗi tạo tài khoản User: $($_.Exception.Message)" -ForegroundColor Yellow
            }
        }
        
        Write-Host "✅ Setup thông tin khách hàng hoàn tất!" -ForegroundColor Green
        
    } catch {
        Write-Host "⚠️ Lỗi trong quá trình setup customer data: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host "💡 Bạn có thể tạo customer data thủ công sau khi services chạy ổn định" -ForegroundColor Blue
    }
}

Write-Host ""
Write-Host "🎉 Cấu hình Keycloak Phone Authentication hoàn tất!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Cấu hình đã tạo:" -ForegroundColor Cyan
Write-Host "   Realm: Kienlongbank (Phone Authentication enabled)" -ForegroundColor White
Write-Host "   Frontend Client: klb-frontend (public)" -ForegroundColor White
Write-Host "   Backend Client: klb-backend-api (confidential)" -ForegroundColor White
Write-Host "   Roles: USER, ADMIN" -ForegroundColor White
Write-Host "   Admin User: 0901234567 / admin123 (ADMIN role)" -ForegroundColor White
Write-Host "   Regular User: 0987654321 / password123 (USER role)" -ForegroundColor White
Write-Host "   Keycloak URL: http://localhost:8090" -ForegroundColor White
Write-Host ""
Write-Host "👥 Thông tin khách hàng đã tạo:" -ForegroundColor Cyan
Write-Host "   Admin: Nguyễn Văn Admin (SĐT: 0901234567)" -ForegroundColor White
Write-Host "   User: Trần Thị User (SĐT: 0987654321)" -ForegroundColor White
Write-Host "   Tài khoản Admin: 001234567890 (Số dư: 10,000,000 VND)" -ForegroundColor White
Write-Host "   Tài khoản User: 009876543210 (Số dư: 5,000,000 VND)" -ForegroundColor White
Write-Host ""
Write-Host "🚀 Bây giờ bạn có thể test đăng nhập bằng số điện thoại!" -ForegroundColor Green
Write-Host ""
Write-Host "💡 Hướng dẫn sử dụng:" -ForegroundColor Yellow
Write-Host "   - Sử dụng số điện thoại thay vì username để đăng nhập" -ForegroundColor White
Write-Host "   - Test với admin: 0901234567 / admin123" -ForegroundColor White
Write-Host "   - Test với user: 0987654321 / password123" -ForegroundColor White
Write-Host "   - Frontend: http://localhost:3000" -ForegroundColor White
Write-Host "   - Backend có thể xử lý cả username và phoneNumber" -ForegroundColor White
