# ============================================================================
# Script Reset Project về trạng thái ban đầu
# ============================================================================

param(
    [switch]$ConfirmAll = $false
)

Write-Host "🔄 Reset KLB Project về trạng thái ban đầu..." -ForegroundColor Red
Write-Host "⚠️  CẢNH BÁO: Script này sẽ xóa TẤT CẢ dữ liệu!" -ForegroundColor Red

if (-not $ConfirmAll) {
    $confirm = Read-Host "Bạn có chắc chắn muốn reset project? (YES để xác nhận)"
    if ($confirm -ne "YES") {
        Write-Host "❌ Hủy bỏ reset project." -ForegroundColor Yellow
        exit
    }
}

# 1. Dọn sạch Docker hoàn toàn
Write-Host "🐳 Dọn sạch Docker hoàn toàn..." -ForegroundColor Yellow

# Dừng tất cả containers
docker stop $(docker ps -aq) 2>$null

# Xóa tất cả containers
docker rm $(docker ps -aq) --force 2>$null

# Xóa tất cả images liên quan
docker images | Select-String "klb-|kienlongbank|customer-service|account-management|loan-service" | ForEach-Object {
    $imageId = ($_ -split '\s+')[2]
    docker rmi $imageId --force 2>$null
}

# Xóa tất cả volumes
docker volume ls | Select-String "postgres|klb" | ForEach-Object {
    $volumeName = ($_ -split '\s+')[1]
    docker volume rm $volumeName --force 2>$null
}

# Dọn sạch Docker system
docker system prune -af --volumes 2>$null

# 2. Xóa tất cả build artifacts
Write-Host "📦 Xóa tất cả build artifacts..." -ForegroundColor Yellow

# Maven targets
Get-ChildItem -Path "kienlongbank-project" -Name "target" -Directory -Recurse | ForEach-Object {
    $targetPath = Join-Path "kienlongbank-project" $_
    Remove-Item $targetPath -Recurse -Force
}

# Node.js artifacts
Remove-Item "klb-frontend\node_modules" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "klb-frontend\build" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "klb-frontend\package-lock.json" -Force -ErrorAction SilentlyContinue

# 3. Xóa tất cả logs và temp files
Write-Host "📄 Xóa logs và temp files..." -ForegroundColor Yellow

# Logs
Get-ChildItem -Path . -Filter "*.log" -Recurse | Remove-Item -Force
Get-ChildItem -Path . -Name "logs" -Directory -Recurse | ForEach-Object {
    Remove-Item $_ -Recurse -Force
}

# Temp files
$tempExtensions = @("*.tmp", "*.temp", "*~", "*.bak", "*.swp")
foreach ($ext in $tempExtensions) {
    Get-ChildItem -Path . -Filter $ext -Recurse | Remove-Item -Force
}

# 4. Xóa IDE files
Write-Host "💻 Xóa IDE files..." -ForegroundColor Yellow
Get-ChildItem -Path . -Name ".vscode" -Directory -Recurse | Remove-Item -Recurse -Force
Get-ChildItem -Path . -Name ".idea" -Directory -Recurse | Remove-Item -Recurse -Force
Get-ChildItem -Path . -Filter "*.iml" -Recurse | Remove-Item -Force

# 5. Reset Git (nếu có)
Write-Host "🌿 Reset Git..." -ForegroundColor Yellow
git clean -fdx 2>$null
git reset --hard HEAD 2>$null

# 6. Thống kê sau reset
Write-Host "`n📊 Thống kê sau reset:" -ForegroundColor Cyan

$dockerContainers = (docker ps -a 2>$null).Count - 1  # Trừ header
$dockerImages = (docker images 2>$null).Count - 1
$dockerVolumes = (docker volume ls 2>$null).Count - 1

Write-Host "  🐳 Docker containers: $dockerContainers" -ForegroundColor Green
Write-Host "  📦 Docker images: $dockerImages" -ForegroundColor Green  
Write-Host "  💾 Docker volumes: $dockerVolumes" -ForegroundColor Green

$projectSize = (Get-ChildItem -Path . -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
$projectSizeMB = [math]::Round($projectSize / 1MB, 2)
Write-Host "  📁 Kích thước project: $projectSizeMB MB" -ForegroundColor Green

Write-Host "`n🎉 Project đã được reset về trạng thái ban đầu!" -ForegroundColor Green
Write-Host "💡 Để bắt đầu lại:" -ForegroundColor Cyan
Write-Host "  1. cd kienlongbank-project" -ForegroundColor Gray
Write-Host "  2. docker-compose up -d" -ForegroundColor Gray
Write-Host "  3. cd ..\klb-frontend && npm install" -ForegroundColor Gray
