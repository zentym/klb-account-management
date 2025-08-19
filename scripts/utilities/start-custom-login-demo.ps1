Write-Host "🚀 KLB Custom Login Demo Setup" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Blue

# Step 1: Check Keycloak
Write-Host "📋 Step 1: Checking Keycloak status..." -ForegroundColor Yellow

try {
    $keycloakCheck = Invoke-RestMethod -Uri "http://localhost:8090/realms/Kienlongbank/.well-known/openid_configuration" -Method Get -ErrorAction Stop
    Write-Host "   ✅ Keycloak is running and realm exists" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Keycloak not accessible. Starting services..." -ForegroundColor Red
    cd "kienlongbank-project"
    docker-compose up -d keycloak
    Write-Host "   ⏳ Waiting for Keycloak to start..." -ForegroundColor Yellow
    Start-Sleep -Seconds 30
    cd ".."
}

# Step 2: Test Direct Grant
Write-Host "📋 Step 2: Testing Direct Grant..." -ForegroundColor Yellow

$testData = @{
    "username" = "testuser"
    "password" = "password123"
    "grant_type" = "password"
    "client_id" = "klb-frontend"
}

try {
    $testResponse = Invoke-RestMethod -Uri "http://localhost:8090/realms/Kienlongbank/protocol/openid-connect/token" -Method Post -Body $testData -ContentType "application/x-www-form-urlencoded" -ErrorAction Stop
    Write-Host "   ✅ Direct Grant is working!" -ForegroundColor Green
    Write-Host "   📝 Token expires in: $($testResponse.expires_in) seconds" -ForegroundColor White
} catch {
    Write-Host "   ❌ Direct Grant failed. Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "   🔧 Running Keycloak setup..." -ForegroundColor Yellow
    & ".\setup-keycloak.ps1"
}

# Step 3: Open Demo
Write-Host "📋 Step 3: Opening Custom Login Demo..." -ForegroundColor Yellow

$htmlFile = Join-Path $PWD "custom-login-demo.html"

if (Test-Path $htmlFile) {
    Write-Host "   ✅ Demo file found: $htmlFile" -ForegroundColor Green
    
    # Start simple HTTP server for CORS
    Write-Host "   🌐 Starting simple HTTP server..." -ForegroundColor Blue
    
    # Try to start Python HTTP server if available
    try {
        $pythonVersion = python --version 2>&1
        Write-Host "   📍 Found Python: $pythonVersion" -ForegroundColor White
        Write-Host "   🚀 Starting server on http://localhost:8000" -ForegroundColor Green
        Write-Host ""
        Write-Host "   📱 DEMO INSTRUCTIONS:" -ForegroundColor Cyan
        Write-Host "   =====================" -ForegroundColor Cyan
        Write-Host "   1. Browser sẽ mở http://localhost:8000/custom-login-demo.html" -ForegroundColor White
        Write-Host "   2. Click 'testuser' button để điền sẵn thông tin" -ForegroundColor White  
        Write-Host "   3. Click 'Đăng nhập' để test Custom Login" -ForegroundColor White
        Write-Host "   4. Xem thông tin user và token sau khi đăng nhập thành công" -ForegroundColor White
        Write-Host "   5. Click 'Đăng xuất' để test logout" -ForegroundColor White
        Write-Host ""
        Write-Host "   ⚠️  CHÚ Ý: Đảm bảo các container đang chạy:" -ForegroundColor Yellow
        Write-Host "   - Keycloak: http://localhost:8090" -ForegroundColor White
        Write-Host "   - Demo: http://localhost:8000/custom-login-demo.html" -ForegroundColor White
        Write-Host ""
        
        # Open browser
        Start-Process "http://localhost:8000/custom-login-demo.html"
        
        # Start HTTP server
        python -m http.server 8000
        
    } catch {
        Write-Host "   ⚠️  Python not found. Opening file directly..." -ForegroundColor Yellow
        Start-Process $htmlFile
    }
} else {
    Write-Host "   ❌ Demo file not found!" -ForegroundColor Red
}

Write-Host ""
Write-Host "🎯 SUMMARY: KLB Custom Login Demo" -ForegroundColor Green
Write-Host "=================================" -ForegroundColor Blue
Write-Host "✅ Keycloak: http://localhost:8090" -ForegroundColor White
Write-Host "✅ Demo Page: http://localhost:8000/custom-login-demo.html" -ForegroundColor White
Write-Host "✅ Test Users: testuser/password123, admin/admin123" -ForegroundColor White
Write-Host "✅ Custom Login UI with Keycloak API integration" -ForegroundColor White
