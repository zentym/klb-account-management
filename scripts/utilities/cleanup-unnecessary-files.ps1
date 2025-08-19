# Script kiểm tra và liệt kê các file không cần thiết trong hệ thống KLB Banking

Write-Host "=== KIỂM TRA CẤU TRÚC HỆ THỐNG KLB BANKING ===" -ForegroundColor Cyan
Write-Host ""

$unnecessaryItems = @()
$totalSize = 0

# Function tính kích thước thư mục
function Get-FolderSize {
    param([string]$path)
    if (Test-Path $path) {
        try {
            $size = (Get-ChildItem -Path $path -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
            return [math]::Round($size / 1MB, 2)
        }
        catch {
            return 0
        }
    }
    return 0
}

# Function kiểm tra và thêm vào danh sách
function Add-UnnecessaryItem {
    param([string]$path, [string]$type, [string]$reason, [string]$priority = "Medium")
    
    if (Test-Path $path) {
        $size = 0
        if ($type -eq "Folder") {
            $size = Get-FolderSize $path
        }
        else {
            $size = [math]::Round((Get-Item $path).Length / 1KB, 2)
        }
        
        $script:unnecessaryItems += [PSCustomObject]@{
            Path     = $path
            Type     = $type
            Reason   = $reason
            Priority = $priority
            Size     = $size
            Unit     = if ($type -eq "Folder") { "MB" } else { "KB" }
        }
        
        $script:totalSize += $size
        
        $color = switch ($priority) {
            "High" { "Red" }
            "Medium" { "Yellow" }
            "Low" { "Gray" }
        }
        
        Write-Host "[$priority] $type`: $path ($size $(if($type -eq 'Folder'){'MB'}else{'KB'})) - $reason" -ForegroundColor $color
    }
}

Write-Host "🔍 Đang quét các file và thư mục không cần thiết..." -ForegroundColor Green
Write-Host ""

# 1. BUILD ARTIFACTS (Ưu tiên cao - có thể xóa ngay)
Write-Host "1. 📦 BUILD ARTIFACTS (có thể tái tạo):" -ForegroundColor Magenta
Add-UnnecessaryItem "e:\dowload\klb-account-management\kienlongbank-project\loan-service\target" "Folder" "Maven build output - có thể xóa và build lại" "High"
Add-UnnecessaryItem "e:\dowload\klb-account-management\kienlongbank-project\customer-service\target" "Folder" "Maven build output - có thể xóa và build lại" "High"
Add-UnnecessaryItem "e:\dowload\klb-account-management\kienlongbank-project\main-app\target" "Folder" "Maven build output - có thể xóa và build lại" "High"
Add-UnnecessaryItem "e:\dowload\klb-account-management\kienlongbank-project\notification-service\target" "Folder" "Maven build output - có thể xóa và build lại" "High"
Add-UnnecessaryItem "e:\dowload\klb-account-management\klb-frontend\build" "Folder" "React build output - có thể xóa và build lại" "High"
Add-UnnecessaryItem "e:\dowload\klb-account-management\klb-frontend\node_modules" "Folder" "Node.js dependencies - có thể cài lại bằng npm install" "High"

# 2. LOG FILES (Ưu tiên trung bình)
Write-Host "`n2. 📄 LOG FILES:" -ForegroundColor Magenta
Get-ChildItem -Path "e:\dowload\klb-account-management" -Recurse -Filter "*.log" -ErrorAction SilentlyContinue | ForEach-Object {
    Add-UnnecessaryItem $_.FullName "File" "Log file - có thể xóa để tiết kiệm dung lượng" "Medium"
}

# 3. CACHE & TEMP FILES
Write-Host "`n3. 🗂️ CACHE & TEMPORARY FILES:" -ForegroundColor Magenta
Add-UnnecessaryItem "e:\dowload\klb-account-management\klb-frontend\.env.local" "File" "Local environment - có thể chứa dữ liệu test không cần thiết" "Medium"

# Tìm các file .tmp
Get-ChildItem -Path "e:\dowload\klb-account-management" -Recurse -Filter "*.tmp" -ErrorAction SilentlyContinue | ForEach-Object {
    Add-UnnecessaryItem $_.FullName "File" "Temporary file - có thể xóa" "High"
}

# 4. IDE CONFIG FILES (Ưu tiên thấp - chỉ xóa nếu không dùng)
Write-Host "`n4. ⚙️ IDE CONFIGURATION:" -ForegroundColor Magenta
Add-UnnecessaryItem "e:\dowload\klb-account-management\.vscode" "Folder" "VS Code settings - chỉ xóa nếu không dùng VS Code" "Low"
Add-UnnecessaryItem "e:\dowload\klb-account-management\.idea" "Folder" "IntelliJ settings - chỉ xóa nếu không dùng IntelliJ" "Low"

# Tìm .DS_Store files (macOS)
Get-ChildItem -Path "e:\dowload\klb-account-management" -Recurse -Name ".DS_Store" -Force -ErrorAction SilentlyContinue | ForEach-Object {
    Add-UnnecessaryItem "e:\dowload\klb-account-management\$_" "File" "macOS system file - có thể xóa" "Medium"
}

# 5. DUPLICATE FILES
Write-Host "`n5. 🔄 DUPLICATE FILES:" -ForegroundColor Magenta
# Kiểm tra package.json ở root có trùng với frontend không
if ((Test-Path "e:\dowload\klb-account-management\package.json") -and (Test-Path "e:\dowload\klb-account-management\klb-frontend\package.json")) {
    try {
        $rootPkg = Get-Content "e:\dowload\klb-account-management\package.json" -Raw | ConvertFrom-Json
        $frontendPkg = Get-Content "e:\dowload\klb-account-management\klb-frontend\package.json" -Raw | ConvertFrom-Json
        
        if ($rootPkg.name -eq $frontendPkg.name -and $rootPkg.version -eq $frontendPkg.version) {
            Add-UnnecessaryItem "e:\dowload\klb-account-management\package.json" "File" "Trùng với klb-frontend/package.json - có thể xóa" "Medium"
        }
    }
    catch {
        Write-Host "⚠️ Không thể so sánh package.json files" -ForegroundColor Yellow
    }
}

# HELP.md files (auto-generated)
Get-ChildItem -Path "e:\dowload\klb-account-management\kienlongbank-project" -Recurse -Filter "HELP.md" -ErrorAction SilentlyContinue | ForEach-Object {
    Add-UnnecessaryItem $_.FullName "File" "Auto-generated Spring Boot help - có thể xóa" "Low"
}

# 6. REDUNDANT SCRIPTS (cần review)
Write-Host "`n6. 📜 SCRIPTS CẦN REVIEW:" -ForegroundColor Magenta
$potentiallyRedundant = @(
    @{Path = "manual-role-fix.ps1"; Reason = "Script fix role thủ công - có thể không cần nữa" },
    @{Path = "fix-user-roles.ps1"; Reason = "Script fix user roles - kiểm tra xem còn dùng không" },
    @{Path = "cleanup-all.ps1"; Reason = "Script cleanup - có thể thay thế bằng script mới này" },
    @{Path = "quick-cleanup.ps1"; Reason = "Script cleanup nhanh - có thể trùng chức năng" },
    @{Path = "reset-project.ps1"; Reason = "Script reset project - cần cẩn thận khi xóa" }
)

foreach ($item in $potentiallyRedundant) {
    $fullPath = "e:\dowload\klb-account-management\$($item.Path)"
    if (Test-Path $fullPath) {
        Add-UnnecessaryItem $fullPath "File" $item.Reason "Low"
    }
}

# SUMMARY & RECOMMENDATIONS
Write-Host "`n" + "="*80 -ForegroundColor Cyan
Write-Host "📊 TÓM TẮT KẾT QUẢ KIỂM TRA" -ForegroundColor Green
Write-Host "="*80 -ForegroundColor Cyan

if ($unnecessaryItems.Count -eq 0) {
    Write-Host "`n✅ Không tìm thấy file không cần thiết nào!" -ForegroundColor Green
}
else {
    # Nhóm theo priority
    $highPriority = $unnecessaryItems | Where-Object Priority -eq "High"
    $mediumPriority = $unnecessaryItems | Where-Object Priority -eq "Medium"  
    $lowPriority = $unnecessaryItems | Where-Object Priority -eq "Low"
    
    if ($highPriority) {
        Write-Host "`n🔴 ƯU TIÊN CAO - CÓ THỂ XÓA NGAY ($($highPriority.Count) items):" -ForegroundColor Red
        $highPriority | Sort-Object Size -Descending | ForEach-Object {
            Write-Host "  • $($_.Type): $($_.Path.Split('\')[-1]) - $($_.Size) $($_.Unit)" -ForegroundColor Red
            Write-Host "    Lý do: $($_.Reason)" -ForegroundColor Gray
        }
    }
    
    if ($mediumPriority) {
        Write-Host "`n🟡 ƯU TIÊN TRUNG BÌNH - CÂN NHẮC XÓA ($($mediumPriority.Count) items):" -ForegroundColor Yellow
        $mediumPriority | Sort-Object Size -Descending | ForEach-Object {
            Write-Host "  • $($_.Type): $($_.Path.Split('\')[-1]) - $($_.Size) $($_.Unit)" -ForegroundColor Yellow
            Write-Host "    Lý do: $($_.Reason)" -ForegroundColor Gray
        }
    }
    
    if ($lowPriority) {
        Write-Host "`n⚪ ƯU TIÊN THẤP - CẦN REVIEW ($($lowPriority.Count) items):" -ForegroundColor Gray
        $lowPriority | Sort-Object Size -Descending | ForEach-Object {
            Write-Host "  • $($_.Type): $($_.Path.Split('\')[-1]) - $($_.Size) $($_.Unit)" -ForegroundColor Gray
            Write-Host "    Lý do: $($_.Reason)" -ForegroundColor Gray
        }
    }
    
    $totalSizeMB = [math]::Round($totalSize, 2)
    Write-Host "`n💾 Tổng dung lượng có thể giải phóng: $totalSizeMB MB" -ForegroundColor Green
    
    Write-Host "`n🛠️ KHUYẾN NGHỊ:" -ForegroundColor Yellow
    Write-Host "1. 🔴 Ưu tiên cao: Chạy 'mvn clean' để xóa target folders" -ForegroundColor White
    Write-Host "2. 🔴 Ưu tiên cao: Xóa node_modules (chạy 'npm install' khi cần)" -ForegroundColor White
    Write-Host "3. 🟡 Ưu tiên trung: Xóa log files cũ để tiết kiệm dung lượng" -ForegroundColor White
    Write-Host "4. ⚪ Ưu tiên thấp: Review các script cũ trước khi xóa" -ForegroundColor White
    
    Write-Host "`n📋 CÁCH XÓA AN TOÀN:" -ForegroundColor Cyan
    Write-Host "• Build artifacts: mvn clean (trong mỗi service folder)" -ForegroundColor Gray
    Write-Host "• Node modules: rm -rf node_modules (trong klb-frontend)" -ForegroundColor Gray
    Write-Host "• Log files: tìm và xóa *.log files" -ForegroundColor Gray
    Write-Host "• IDE configs: chỉ xóa nếu không sử dụng IDE đó" -ForegroundColor Gray
}

Write-Host "`n📚 Tài liệu tham khảo:" -ForegroundColor Cyan
Write-Host "  • Main project: kienlongbank-project/README.md" -ForegroundColor Gray
Write-Host "  • Frontend: klb-frontend/README.md" -ForegroundColor Gray
Write-Host "  • Legacy: legacy-scripts/README.md" -ForegroundColor Gray