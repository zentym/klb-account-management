# Script dọn dẹp an toàn các file không cần thiết

Write-Host "=== DỌNG DẸP AN TOÀN HỆ THỐNG KLB BANKING ===" -ForegroundColor Cyan
Write-Host ""

$cleanupActions = @()
$totalSavedSpace = 0

function Show-CleanupMenu {
    Write-Host "📋 Chọn các mục muốn dọn dẹp:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "1. 🔴 Maven Target Folders (Khuyến nghị - An toàn 100%)" -ForegroundColor Red
    Write-Host "2. 🔴 Node Modules (Khuyến nghị - Cần npm install sau)" -ForegroundColor Red  
    Write-Host "3. 🟡 Log Files (.log)" -ForegroundColor Yellow
    Write-Host "4. 🟡 Cache Files (.DS_Store, .env.local)" -ForegroundColor Yellow
    Write-Host "5. 🟡 Duplicate package.json ở root" -ForegroundColor Yellow
    Write-Host "6. ⚪ HELP.md files (Auto-generated)" -ForegroundColor Gray
    Write-Host "7. 🧹 Dọn dẹp tất cả (trừ scripts)" -ForegroundColor Green
    Write-Host "0. ❌ Thoát" -ForegroundColor Red
    Write-Host ""
}

function Clean-MavenTargets {
    Write-Host "🧹 Đang dọn dẹp Maven target folders..." -ForegroundColor Green
    
    $mavenProjects = @(
        "e:\dowload\klb-account-management\kienlongbank-project\loan-service",
        "e:\dowload\klb-account-management\kienlongbank-project\customer-service",
        "e:\dowload\klb-account-management\kienlongbank-project\main-app", 
        "e:\dowload\klb-account-management\kienlongbank-project\notification-service"
    )
    
    $cleaned = 0
    $savedSpace = 0
    
    foreach ($project in $mavenProjects) {
        $targetPath = Join-Path $project "target"
        if (Test-Path $targetPath) {
            try {
                $size = (Get-ChildItem -Path $targetPath -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
                Remove-Item $targetPath -Recurse -Force -ErrorAction Stop
                $savedSpace += $size
                $cleaned++
                Write-Host "  ✅ Đã xóa: $targetPath" -ForegroundColor Green
            } catch {
                Write-Host "  ❌ Không thể xóa: $targetPath - $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }
    
    Write-Host "📊 Kết quả: Đã xóa $cleaned target folders, tiết kiệm $([math]::Round($savedSpace / 1MB, 2)) MB" -ForegroundColor Cyan
    return $savedSpace
}

function Clean-NodeModules {
    Write-Host "🧹 Đang dọn dẹp Node modules..." -ForegroundColor Green
    
    $nodeModulesPath = "e:\dowload\klb-account-management\klb-frontend\node_modules"
    
    if (Test-Path $nodeModulesPath) {
        try {
            $size = (Get-ChildItem -Path $nodeModulesPath -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
            Remove-Item $nodeModulesPath -Recurse -Force -ErrorAction Stop
            Write-Host "  ✅ Đã xóa: node_modules" -ForegroundColor Green
            Write-Host "  💡 Để khôi phục, chạy: cd klb-frontend && npm install" -ForegroundColor Yellow
            Write-Host "📊 Tiết kiệm: $([math]::Round($size / 1MB, 2)) MB" -ForegroundColor Cyan
            return $size
        } catch {
            Write-Host "  ❌ Không thể xóa node_modules: $($_.Exception.Message)" -ForegroundColor Red
            return 0
        }
    } else {
        Write-Host "  ℹ️ Không tìm thấy node_modules" -ForegroundColor Blue
        return 0
    }
}

function Clean-LogFiles {
    Write-Host "🧹 Đang dọn dẹp log files..." -ForegroundColor Green
    
    $logFiles = Get-ChildItem -Path "e:\dowload\klb-account-management" -Recurse -Filter "*.log" -ErrorAction SilentlyContinue
    $cleaned = 0
    $savedSpace = 0
    
    foreach ($logFile in $logFiles) {
        try {
            $size = $logFile.Length
            Remove-Item $logFile.FullName -Force -ErrorAction Stop
            $savedSpace += $size
            $cleaned++
            Write-Host "  ✅ Đã xóa: $($logFile.Name)" -ForegroundColor Green
        } catch {
            Write-Host "  ❌ Không thể xóa: $($logFile.Name) - $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    Write-Host "📊 Kết quả: Đã xóa $cleaned log files, tiết kiệm $([math]::Round($savedSpace / 1KB, 2)) KB" -ForegroundColor Cyan
    return $savedSpace
}

function Clean-CacheFiles {
    Write-Host "🧹 Đang dọn dẹp cache files..." -ForegroundColor Green
    
    $cacheFiles = @(
        "e:\dowload\klb-account-management\klb-frontend\.env.local"
    )
    
    # Tìm .DS_Store files
    $dsStoreFiles = Get-ChildItem -Path "e:\dowload\klb-account-management" -Recurse -Name ".DS_Store" -Force -ErrorAction SilentlyContinue
    
    $cleaned = 0
    $savedSpace = 0
    
    # Xóa .env.local
    foreach ($cacheFile in $cacheFiles) {
        if (Test-Path $cacheFile) {
            try {
                $size = (Get-Item $cacheFile).Length
                Remove-Item $cacheFile -Force -ErrorAction Stop
                $savedSpace += $size
                $cleaned++
                Write-Host "  ✅ Đã xóa: $($cacheFile.Split('\')[-1])" -ForegroundColor Green
            } catch {
                Write-Host "  ❌ Không thể xóa: $($cacheFile.Split('\')[-1]) - $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }
    
    # Xóa .DS_Store files
    foreach ($dsFile in $dsStoreFiles) {
        $fullPath = "e:\dowload\klb-account-management\$dsFile"
        if (Test-Path $fullPath) {
            try {
                $size = (Get-Item $fullPath).Length
                Remove-Item $fullPath -Force -ErrorAction Stop
                $savedSpace += $size
                $cleaned++
                Write-Host "  ✅ Đã xóa: .DS_Store" -ForegroundColor Green
            } catch {
                Write-Host "  ❌ Không thể xóa .DS_Store: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }
    
    Write-Host "📊 Kết quả: Đã xóa $cleaned cache files, tiết kiệm $([math]::Round($savedSpace / 1KB, 2)) KB" -ForegroundColor Cyan
    return $savedSpace
}

function Clean-DuplicatePackageJson {
    Write-Host "🧹 Đang kiểm tra duplicate package.json..." -ForegroundColor Green
    
    $rootPackage = "e:\dowload\klb-account-management\package.json"
    $frontendPackage = "e:\dowload\klb-account-management\klb-frontend\package.json"
    
    if ((Test-Path $rootPackage) -and (Test-Path $frontendPackage)) {
        try {
            $rootContent = Get-Content $rootPackage -Raw | ConvertFrom-Json
            $frontendContent = Get-Content $frontendPackage -Raw | ConvertFrom-Json
            
            if ($rootContent.name -eq $frontendContent.name -and $rootContent.version -eq $frontendContent.version) {
                $size = (Get-Item $rootPackage).Length
                Remove-Item $rootPackage -Force -ErrorAction Stop
                Write-Host "  ✅ Đã xóa duplicate package.json ở root" -ForegroundColor Green
                Write-Host "📊 Tiết kiệm: $([math]::Round($size / 1KB, 2)) KB" -ForegroundColor Cyan
                return $size
            } else {
                Write-Host "  ℹ️ package.json ở root khác với frontend, giữ lại" -ForegroundColor Blue
                return 0
            }
        } catch {
            Write-Host "  ❌ Không thể xử lý package.json: $($_.Exception.Message)" -ForegroundColor Red
            return 0
        }
    } else {
        Write-Host "  ℹ️ Không tìm thấy duplicate package.json" -ForegroundColor Blue
        return 0
    }
}

function Clean-HelpFiles {
    Write-Host "🧹 Đang dọn dẹp HELP.md files..." -ForegroundColor Green
    
    $helpFiles = Get-ChildItem -Path "e:\dowload\klb-account-management\kienlongbank-project" -Recurse -Filter "HELP.md" -ErrorAction SilentlyContinue
    $cleaned = 0
    $savedSpace = 0
    
    foreach ($helpFile in $helpFiles) {
        try {
            $size = $helpFile.Length
            Remove-Item $helpFile.FullName -Force -ErrorAction Stop
            $savedSpace += $size
            $cleaned++
            Write-Host "  ✅ Đã xóa: $($helpFile.FullName.Replace('e:\dowload\klb-account-management\', ''))" -ForegroundColor Green
        } catch {
            Write-Host "  ❌ Không thể xóa: $($helpFile.Name) - $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    Write-Host "📊 Kết quả: Đã xóa $cleaned HELP.md files, tiết kiệm $([math]::Round($savedSpace / 1KB, 2)) KB" -ForegroundColor Cyan
    return $savedSpace
}

# Main execution
do {
    Show-CleanupMenu
    $choice = Read-Host "Nhập lựa chọn (0-7)"
    
    switch ($choice) {
        "1" { 
            $totalSavedSpace += Clean-MavenTargets
            Write-Host "`nNhấn Enter để tiếp tục..." -ForegroundColor Gray
            Read-Host
        }
        "2" { 
            $totalSavedSpace += Clean-NodeModules
            Write-Host "`nNhấn Enter để tiếp tục..." -ForegroundColor Gray
            Read-Host
        }
        "3" { 
            $totalSavedSpace += Clean-LogFiles
            Write-Host "`nNhấn Enter để tiếp tục..." -ForegroundColor Gray
            Read-Host
        }
        "4" { 
            $totalSavedSpace += Clean-CacheFiles
            Write-Host "`nNhấn Enter để tiếp tục..." -ForegroundColor Gray
            Read-Host
        }
        "5" { 
            $totalSavedSpace += Clean-DuplicatePackageJson
            Write-Host "`nNhấn Enter để tiếp tục..." -ForegroundColor Gray
            Read-Host
        }
        "6" { 
            $totalSavedSpace += Clean-HelpFiles
            Write-Host "`nNhấn Enter để tiếp tục..." -ForegroundColor Gray
            Read-Host
        }
        "7" {
            Write-Host "`n🧹 Thực hiện dọn dẹp toàn bộ (trừ scripts)..." -ForegroundColor Green
            $totalSavedSpace += Clean-MavenTargets
            $totalSavedSpace += Clean-NodeModules  
            $totalSavedSpace += Clean-LogFiles
            $totalSavedSpace += Clean-CacheFiles
            $totalSavedSpace += Clean-DuplicatePackageJson
            $totalSavedSpace += Clean-HelpFiles
            Write-Host "`nNhấn Enter để tiếp tục..." -ForegroundColor Gray
            Read-Host
        }
        "0" { 
            Write-Host "`n👋 Thoát chương trình." -ForegroundColor Blue
        }
        default {
            Write-Host "`n❌ Lựa chọn không hợp lệ!" -ForegroundColor Red
            Write-Host "Nhấn Enter để thử lại..." -ForegroundColor Gray
            Read-Host
        }
    }
    
    if ($choice -ne "0") {
        Write-Host "`n💾 Tổng dung lượng đã tiết kiệm: $([math]::Round($totalSavedSpace / 1MB, 2)) MB" -ForegroundColor Green
        Write-Host ""
    }
    
} while ($choice -ne "0")

Write-Host "`n✅ Hoàn thành! Tổng dung lượng đã tiết kiệm: $([math]::Round($totalSavedSpace / 1MB, 2)) MB" -ForegroundColor Green

Write-Host "`n📋 LƯU Ý SAU KHI DỌN DẸP:" -ForegroundColor Yellow
Write-Host "• Để build lại Maven projects: mvn compile hoặc mvn package" -ForegroundColor Gray
Write-Host "• Để cài lại node_modules: cd klb-frontend && npm install" -ForegroundColor Gray
Write-Host "• Kiểm tra các service vẫn hoạt động bình thường" -ForegroundColor Gray
