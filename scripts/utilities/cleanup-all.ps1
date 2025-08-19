# ============================================================================
# Script dọn sạch tất cả cho KLB Account Management Project
# ============================================================================

param(
    [switch]$Force = $false,
    [switch]$KeepDatabase = $false,
    [switch]$SkipDocker = $false,
    [switch]$SkipBuild = $false,
    [switch]$Verbose = $false
)

Write-Host "🧹 Bắt đầu dọn sạch KLB Account Management Project..." -ForegroundColor Cyan

# Function để log với màu sắc
function Write-Log {
    param($Message, $Color = "White")
    if ($Verbose) {
        Write-Host "  $Message" -ForegroundColor $Color
    }
}

# Function để xác nhận
function Confirm-Action {
    param($Message)
    if ($Force) {
        return $true
    }
    $response = Read-Host "$Message (y/N)"
    return $response -eq 'y' -or $response -eq 'Y'
}

# ============================================================================
# 1. Dọn sạch Docker Containers và Images
# ============================================================================
if (-not $SkipDocker) {
    Write-Host "🐳 Dọn sạch Docker containers và images..." -ForegroundColor Yellow
    
    # Di chuyển đến thư mục docker-compose
    $dockerPath = Join-Path $PSScriptRoot "kienlongbank-project"
    if (Test-Path $dockerPath) {
        Push-Location $dockerPath
        
        try {
            # Dừng và xóa containers
            Write-Log "Dừng tất cả containers..." "Gray"
            docker-compose down --remove-orphans 2>$null
            
            # Xóa containers theo tên cụ thể
            $containers = @(
                "klb-postgres",
                "klb-postgres-customer", 
                "klb-customer-service",
                "klb-account-management",
                "klb-loan-service",
                "klb-frontend"
            )
            
            foreach ($container in $containers) {
                if (docker ps -a --format "table {{.Names}}" | Select-String $container) {
                    Write-Log "Xóa container: $container" "Gray"
                    docker rm -f $container 2>$null
                }
            }
            
            # Xóa images được build
            $images = docker images --format "table {{.Repository}}:{{.Tag}}" | Where-Object { 
                $_ -match "kienlongbank-project" -or 
                $_ -match "klb-" -or
                $_ -match "customer-service" -or
                $_ -match "account-management" -or
                $_ -match "loan-service"
            }
            
            if ($images) {
                Write-Log "Xóa images được build..." "Gray"
                $images | ForEach-Object {
                    if ($_ -notmatch "REPOSITORY") {
                        docker rmi $_ --force 2>$null
                    }
                }
            }
            
            # Xóa volumes (nếu không giữ database)
            if (-not $KeepDatabase) {
                Write-Log "Xóa Docker volumes..." "Gray"
                docker volume rm kienlongbank-project_postgres_data 2>$null
                docker volume rm kienlongbank-project_postgres_customer_data 2>$null
            }
            
        }
        catch {
            Write-Warning "Lỗi khi dọn sạch Docker: $($_.Exception.Message)"
        }
        finally {
            Pop-Location
        }
    }
    
    # Dọn sạch Docker system (tùy chọn)
    if (Confirm-Action "Dọn sạch Docker system (dangling images, unused networks)?") {
        Write-Log "Dọn sạch Docker system..." "Gray"
        docker system prune -f 2>$null
    }
}

# ============================================================================
# 2. Dọn sạch Maven Build Artifacts
# ============================================================================
if (-not $SkipBuild) {
    Write-Host "📦 Dọn sạch Maven build artifacts..." -ForegroundColor Yellow
    
    $mavenProjects = @(
        "kienlongbank-project\customer-service",
        "kienlongbank-project\loan-service", 
        "kienlongbank-project\main-app"
    )
    
    foreach ($project in $mavenProjects) {
        $projectPath = Join-Path $PSScriptRoot $project
        if (Test-Path $projectPath) {
            Push-Location $projectPath
            
            try {
                Write-Log "Dọn sạch Maven cho $project..." "Gray"
                if (Test-Path "pom.xml") {
                    mvn clean 2>$null
                }
                
                # Xóa thư mục target nếu vẫn còn
                if (Test-Path "target") {
                    Remove-Item "target" -Recurse -Force
                    Write-Log "Đã xóa thư mục target" "Green"
                }
                
            }
            catch {
                Write-Warning "Lỗi khi dọn sạch Maven cho $project`: $($_.Exception.Message)"
            }
            finally {
                Pop-Location
            }
        }
    }
}

# ============================================================================
# 3. Dọn sạch Node.js Build Artifacts
# ============================================================================
Write-Host "📱 Dọn sạch Node.js build artifacts..." -ForegroundColor Yellow

$frontendPath = Join-Path $PSScriptRoot "klb-frontend"
if (Test-Path $frontendPath) {
    Push-Location $frontendPath
    
    try {
        # Xóa node_modules
        if (Test-Path "node_modules") {
            Write-Log "Xóa node_modules..." "Gray"
            Remove-Item "node_modules" -Recurse -Force
            Write-Log "Đã xóa node_modules" "Green"
        }
        
        # Xóa build directory
        if (Test-Path "build") {
            Write-Log "Xóa thư mục build..." "Gray"
            Remove-Item "build" -Recurse -Force
            Write-Log "Đã xóa thư mục build" "Green"
        }
        
        # Xóa các file lock
        $lockFiles = @("package-lock.json", "yarn.lock", "pnpm-lock.yaml")
        foreach ($lockFile in $lockFiles) {
            if (Test-Path $lockFile) {
                Remove-Item $lockFile -Force
                Write-Log "Đã xóa $lockFile" "Green"
            }
        }
        
    }
    catch {
        Write-Warning "Lỗi khi dọn sạch frontend: $($_.Exception.Message)"
    }
    finally {
        Pop-Location
    }
}

# ============================================================================
# 4. Dọn sạch Log Files
# ============================================================================
Write-Host "📄 Dọn sạch log files..." -ForegroundColor Yellow

$logPatterns = @(
    "*.log",
    "logs\*",
    "**\logs\*",
    "**\target\*.log",
    "nohup.out"
)

foreach ($pattern in $logPatterns) {
    $logFiles = Get-ChildItem -Path $PSScriptRoot -Filter $pattern -Recurse -ErrorAction SilentlyContinue
    foreach ($logFile in $logFiles) {
        try {
            Remove-Item $logFile.FullName -Force
            Write-Log "Đã xóa log: $($logFile.Name)" "Green"
        }
        catch {
            Write-Log "Không thể xóa: $($logFile.FullName)" "Red"
        }
    }
}

# ============================================================================
# 5. Dọn sạch Temporary Files
# ============================================================================
Write-Host "🗑️ Dọn sạch temporary files..." -ForegroundColor Yellow

$tempPatterns = @(
    "*.tmp",
    "*.temp", 
    "*~",
    "*.bak",
    "*.swp",
    ".DS_Store",
    "Thumbs.db",
    "*.class"
)

foreach ($pattern in $tempPatterns) {
    $tempFiles = Get-ChildItem -Path $PSScriptRoot -Filter $pattern -Recurse -ErrorAction SilentlyContinue
    foreach ($tempFile in $tempFiles) {
        try {
            Remove-Item $tempFile.FullName -Force
            Write-Log "Đã xóa temp file: $($tempFile.Name)" "Green"
        }
        catch {
            Write-Log "Không thể xóa: $($tempFile.FullName)" "Red"
        }
    }
}

# ============================================================================
# 6. Dọn sạch IDE Files (tùy chọn)
# ============================================================================
if (Confirm-Action "Dọn sạch IDE files (.vscode, .idea, *.iml)?") {
    Write-Host "💻 Dọn sạch IDE files..." -ForegroundColor Yellow
    
    $idePatterns = @(
        ".vscode\settings.json",
        ".idea",
        "*.iml",
        "*.ipr",
        "*.iws",
        ".project",
        ".classpath",
        ".settings"
    )
    
    foreach ($pattern in $idePatterns) {
        $ideFiles = Get-ChildItem -Path $PSScriptRoot -Filter $pattern -Recurse -ErrorAction SilentlyContinue
        foreach ($ideFile in $ideFiles) {
            try {
                if ($ideFile.PSIsContainer) {
                    Remove-Item $ideFile.FullName -Recurse -Force
                }
                else {
                    Remove-Item $ideFile.FullName -Force
                }
                Write-Log "Đã xóa IDE file: $($ideFile.Name)" "Green"
            }
            catch {
                Write-Log "Không thể xóa: $($ideFile.FullName)" "Red"
            }
        }
    }
}

# ============================================================================
# 7. Dọn sạch Git (tùy chọn)
# ============================================================================
if (Confirm-Action "Dọn sạch Git cache và refs?") {
    Write-Host "🌿 Dọn sạch Git..." -ForegroundColor Yellow
    
    try {
        git gc --aggressive --prune=now 2>$null
        git remote prune origin 2>$null
        Write-Log "Đã dọn sạch Git cache" "Green"
    }
    catch {
        Write-Log "Không thể dọn sạch Git: $($_.Exception.Message)" "Red"
    }
}

# ============================================================================
# 8. Thống kê kết quả
# ============================================================================
Write-Host "`n📊 Thống kê sau khi dọn sạch:" -ForegroundColor Cyan

# Kiểm tra Docker
$dockerContainers = (docker ps -a --format "table {{.Names}}" 2>$null | Select-String "klb-").Count
$dockerImages = (docker images --format "table {{.Repository}}" 2>$null | Select-String "kienlongbank").Count

Write-Host "  🐳 Docker containers còn lại: $dockerContainers" -ForegroundColor $(if ($dockerContainers -eq 0) { "Green" } else { "Yellow" })
Write-Host "  📦 Docker images còn lại: $dockerImages" -ForegroundColor $(if ($dockerImages -eq 0) { "Green" } else { "Yellow" })

# Kiểm tra kích thước thư mục
$projectSize = (Get-ChildItem -Path $PSScriptRoot -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
$projectSizeMB = [math]::Round($projectSize / 1MB, 2)
Write-Host "  📁 Kích thước project: $projectSizeMB MB" -ForegroundColor White

Write-Host "`n✅ Hoàn thành dọn sạch project!" -ForegroundColor Green
Write-Host "💡 Sử dụng các tham số:" -ForegroundColor Cyan
Write-Host "  -Force          : Không hỏi xác nhận" -ForegroundColor Gray
Write-Host "  -KeepDatabase   : Giữ lại database volumes" -ForegroundColor Gray
Write-Host "  -SkipDocker     : Bỏ qua dọn sạch Docker" -ForegroundColor Gray
Write-Host "  -SkipBuild      : Bỏ qua dọn sạch build artifacts" -ForegroundColor Gray
Write-Host "  -Verbose        : Hiển thị thông tin chi tiết" -ForegroundColor Gray
