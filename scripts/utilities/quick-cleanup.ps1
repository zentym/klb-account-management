# ============================================================================
# Script dọn sạch nhanh cho KLB Account Management Project
# ============================================================================

Write-Host "🚀 Dọn sạch nhanh KLB Project..." -ForegroundColor Cyan

# 1. Dừng tất cả containers
Write-Host "🐳 Dừng Docker containers..." -ForegroundColor Yellow
docker-compose -f "kienlongbank-project\docker-compose.yml" down --remove-orphans 2>$null

# Dừng containers theo tên
$containers = @("klb-postgres", "klb-postgres-customer", "klb-customer-service", "klb-account-management", "klb-loan-service")
foreach ($container in $containers) {
    docker stop $container 2>$null
    docker rm $container 2>$null
}

# 2. Dọn sạch Maven build
Write-Host "📦 Dọn sạch Maven..." -ForegroundColor Yellow
$mavenDirs = Get-ChildItem -Path "kienlongbank-project" -Directory | Where-Object { Test-Path "$($_.FullName)\pom.xml" }
foreach ($dir in $mavenDirs) {
    if (Test-Path "$($dir.FullName)\target") {
        Remove-Item "$($dir.FullName)\target" -Recurse -Force
        Write-Host "  ✅ Xóa target: $($dir.Name)" -ForegroundColor Green
    }
}

# 3. Dọn sạch Frontend
Write-Host "📱 Dọn sạch Frontend..." -ForegroundColor Yellow
if (Test-Path "klb-frontend\node_modules") {
    Remove-Item "klb-frontend\node_modules" -Recurse -Force
    Write-Host "  ✅ Xóa node_modules" -ForegroundColor Green
}
if (Test-Path "klb-frontend\build") {
    Remove-Item "klb-frontend\build" -Recurse -Force  
    Write-Host "  ✅ Xóa build directory" -ForegroundColor Green
}

# 4. Dọn sạch logs
Write-Host "📄 Dọn sạch logs..." -ForegroundColor Yellow
Get-ChildItem -Path . -Filter "*.log" -Recurse | Remove-Item -Force
Write-Host "  ✅ Xóa tất cả log files" -ForegroundColor Green

Write-Host "`n✅ Hoàn thành dọn sạch nhanh!" -ForegroundColor Green
