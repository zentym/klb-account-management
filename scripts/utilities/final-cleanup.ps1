# Script dọn dẹp cuối cùng cho dự án KLB Account Management
# Chạy script này để xóa các file và thư mục không cần thiết

Write-Host "🧹 Bắt đầu dọn dẹp dự án..." -ForegroundColor Green

# Xóa node_modules nếu muốn (có thể cài lại bằng npm install)
$removeNodeModules = Read-Host "Bạn có muốn xóa thư mục node_modules? (y/N)"
if ($removeNodeModules -eq "y" -or $removeNodeModules -eq "Y") {
    if (Test-Path "node_modules") {
        Write-Host "🗑️  Đang xóa thư mục node_modules..." -ForegroundColor Yellow
        Remove-Item -Path "node_modules" -Recurse -Force
        Write-Host "✅ Đã xóa node_modules" -ForegroundColor Green
    }
}

# Xóa thư mục legacy-scripts sau khi xác nhận
$removeLegacy = Read-Host "Bạn có muốn xóa thư mục legacy-scripts? (y/N)"
if ($removeLegacy -eq "y" -or $removeLegacy -eq "Y") {
    if (Test-Path "legacy-scripts") {
        Write-Host "🗑️  Đang xóa thư mục legacy-scripts..." -ForegroundColor Yellow
        Remove-Item -Path "legacy-scripts" -Recurse -Force
        Write-Host "✅ Đã xóa legacy-scripts" -ForegroundColor Green
    }
}

# Tìm và xóa các file log cũ
Write-Host "🔍 Tìm kiếm file log cũ..." -ForegroundColor Yellow
$logFiles = Get-ChildItem -Recurse -Include "*.log", "*.tmp", "*.bak" -ErrorAction SilentlyContinue
if ($logFiles.Count -gt 0) {
    Write-Host "Tìm thấy $($logFiles.Count) file log/temp:" -ForegroundColor Yellow
    $logFiles | ForEach-Object { Write-Host "  - $($_.FullName)" }
    $removeLog = Read-Host "Bạn có muốn xóa các file này? (y/N)"
    if ($removeLog -eq "y" -or $removeLog -eq "Y") {
        $logFiles | Remove-Item -Force
        Write-Host "✅ Đã xóa các file log/temp" -ForegroundColor Green
    }
}

# Hiển thị cấu trúc cuối cùng
Write-Host "`n📊 Cấu trúc dự án sau khi dọn dẹp:" -ForegroundColor Cyan
tree /F /A

Write-Host "`n🎉 Hoàn thành dọn dẹp dự án!" -ForegroundColor Green
Write-Host "📚 Xem file README.md để biết thêm chi tiết về cấu trúc mới" -ForegroundColor Cyan
