# ============================================================================
# Script kiểm tra trạng thái KLB Project  
# ============================================================================

Write-Host "📊 TRẠNG THÁI KLB ACCOUNT MANAGEMENT PROJECT" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Gray

# 1. Kiểm tra Docker
Write-Host "`n🐳 DOCKER STATUS:" -ForegroundColor Yellow

$runningContainers = docker ps --format "table {{.Names}}\t{{.Status}}" 2>$null | Select-String "klb-"
$allContainers = docker ps -a --format "table {{.Names}}\t{{.Status}}" 2>$null | Select-String "klb-"

if ($runningContainers) {
    Write-Host "  Running Containers:" -ForegroundColor Green
    $runningContainers | ForEach-Object { Write-Host "    $($_.ToString())" -ForegroundColor White }
} else {
    Write-Host "  ❌ Không có container nào đang chạy" -ForegroundColor Red
}

if ($allContainers) {
    Write-Host "`n  All Containers:" -ForegroundColor Gray
    $allContainers | ForEach-Object { Write-Host "    $($_.ToString())" -ForegroundColor Gray }
}

# Kiểm tra Docker Images
$images = docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" 2>$null | Select-String "klb-|kienlongbank|customer-service|account-management"
if ($images) {
    Write-Host "`n  Project Images:" -ForegroundColor Gray
    $images | ForEach-Object { Write-Host "    $($_.ToString())" -ForegroundColor Gray }
}

# Kiểm tra Docker Volumes
$volumes = docker volume ls --format "table {{.Name}}" 2>$null | Select-String "postgres|klb"
if ($volumes) {
    Write-Host "`n  Project Volumes:" -ForegroundColor Gray
    $volumes | ForEach-Object { Write-Host "    $($_.ToString())" -ForegroundColor Gray }
}

# 2. Kiểm tra Maven Projects
Write-Host "`n📦 MAVEN PROJECTS:" -ForegroundColor Yellow

$mavenProjects = Get-ChildItem -Path "kienlongbank-project" -Directory | Where-Object { Test-Path "$($_.FullName)\pom.xml" }
foreach ($project in $mavenProjects) {
    $targetExists = Test-Path "$($project.FullName)\target"
    $jarFiles = Get-ChildItem -Path "$($project.FullName)\target" -Filter "*.jar" -ErrorAction SilentlyContinue
    
    $status = if ($targetExists -and $jarFiles) { "✅ Built" } elseif ($targetExists) { "⚠️  Compiled" } else { "❌ Not built" }
    Write-Host "  $($project.Name): $status" -ForegroundColor White
    
    if ($jarFiles) {
        $jarFiles | ForEach-Object { 
            $sizeMB = [math]::Round($_.Length / 1MB, 2)
            Write-Host "    └─ $($_.Name) ($sizeMB MB)" -ForegroundColor Gray 
        }
    }
}

# 3. Kiểm tra Frontend
Write-Host "`n📱 FRONTEND STATUS:" -ForegroundColor Yellow

$frontendPath = "klb-frontend"
if (Test-Path $frontendPath) {
    $nodeModulesExists = Test-Path "$frontendPath\node_modules"
    $buildExists = Test-Path "$frontendPath\build"
    $packageJsonExists = Test-Path "$frontendPath\package.json"
    
    Write-Host "  Package.json: $(if($packageJsonExists) {'✅'} else {'❌'})" -ForegroundColor White
    Write-Host "  Node modules: $(if($nodeModulesExists) {'✅ Installed'} else {'❌ Not installed'})" -ForegroundColor White
    Write-Host "  Build folder: $(if($buildExists) {'✅ Exists'} else {'❌ Not built'})" -ForegroundColor White
    
    if ($buildExists) {
        $buildSize = (Get-ChildItem -Path "$frontendPath\build" -Recurse | Measure-Object -Property Length -Sum).Sum
        $buildSizeMB = [math]::Round($buildSize / 1MB, 2)
        Write-Host "    └─ Build size: $buildSizeMB MB" -ForegroundColor Gray
    }
} else {
    Write-Host "  ❌ Frontend folder not found" -ForegroundColor Red
}

# 4. Kiểm tra Ports
Write-Host "`n🔌 PORT STATUS:" -ForegroundColor Yellow

$ports = @(
    @{Port=8080; Service="Main App"},
    @{Port=8082; Service="Customer Service"},
    @{Port=8083; Service="Loan Service"},
    @{Port=3000; Service="Frontend"},
    @{Port=5432; Service="PostgreSQL Main"},
    @{Port=5433; Service="PostgreSQL Customer"}
)

foreach ($portInfo in $ports) {
    $port = $portInfo.Port
    $service = $portInfo.Service
    
    try {
        $connection = Test-NetConnection -ComputerName localhost -Port $port -WarningAction SilentlyContinue
        $status = if ($connection.TcpTestSucceeded) { "✅ LISTENING" } else { "❌ CLOSED" }
        Write-Host "  $port ($service): $status" -ForegroundColor White
    } catch {
        Write-Host "  $port ($service): ❌ CLOSED" -ForegroundColor White
    }
}

# 5. Thống kê Files
Write-Host "`n📁 PROJECT FILES:" -ForegroundColor Yellow

$projectSize = (Get-ChildItem -Path . -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
$projectSizeMB = [math]::Round($projectSize / 1MB, 2)

$fileCount = (Get-ChildItem -Path . -Recurse -File -ErrorAction SilentlyContinue).Count
$folderCount = (Get-ChildItem -Path . -Recurse -Directory -ErrorAction SilentlyContinue).Count

Write-Host "  Total size: $projectSizeMB MB" -ForegroundColor White
Write-Host "  Files: $fileCount" -ForegroundColor White  
Write-Host "  Folders: $folderCount" -ForegroundColor White

# 6. Logs và Temp Files
Write-Host "`n📄 LOGS & TEMP FILES:" -ForegroundColor Yellow

$logFiles = Get-ChildItem -Path . -Filter "*.log" -Recurse -ErrorAction SilentlyContinue
$tempFiles = Get-ChildItem -Path . -Filter "*.tmp" -Recurse -ErrorAction SilentlyContinue

Write-Host "  Log files: $($logFiles.Count)" -ForegroundColor White
Write-Host "  Temp files: $($tempFiles.Count)" -ForegroundColor White

if ($logFiles.Count -gt 0) {
    $logSize = ($logFiles | Measure-Object -Property Length -Sum).Sum
    $logSizeMB = [math]::Round($logSize / 1MB, 2)
    Write-Host "    └─ Log size: $logSizeMB MB" -ForegroundColor Gray
}

# 7. Recommendations
Write-Host "`n💡 RECOMMENDATIONS:" -ForegroundColor Cyan

if (-not $runningContainers) {
    Write-Host "  • Chạy: docker-compose up -d để khởi động services" -ForegroundColor Yellow
}

if (-not (Test-Path "klb-frontend\node_modules")) {
    Write-Host "  • Chạy: cd klb-frontend && npm install" -ForegroundColor Yellow
}

$unbuitMaven = $mavenProjects | Where-Object { -not (Test-Path "$($_.FullName)\target") }
if ($unbuitMaven) {
    Write-Host "  • Build Maven projects: mvn clean install" -ForegroundColor Yellow
}

if ($logFiles.Count -gt 10) {
    Write-Host "  • Nhiều log files, nên dọn sạch: .\quick-cleanup.ps1" -ForegroundColor Yellow
}

Write-Host "`n🔗 QUICK ACTIONS:" -ForegroundColor Cyan
Write-Host "  .\cleanup-menu.bat     - Menu dọn sạch" -ForegroundColor Gray
Write-Host "  .\quick-cleanup.ps1    - Dọn sạch nhanh" -ForegroundColor Gray
Write-Host "  .\cleanup-all.ps1      - Dọn sạch đầy đủ" -ForegroundColor Gray
Write-Host "  .\reset-project.ps1    - Reset hoàn toàn" -ForegroundColor Gray

Write-Host "`n" + "=" * 60 -ForegroundColor Gray
