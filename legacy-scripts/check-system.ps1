# KLB Account Management - System Check
Write-Host ""
Write-Host "🔍 KLB Account Management System Check" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

$allGood = $true

# Check 1: Docker
Write-Host "[1/5] Checking Docker..." -ForegroundColor Yellow
try {
    $dockerVersion = docker --version 2>$null
    if ($dockerVersion) {
        Write-Host "✓ Docker is installed: $dockerVersion" -ForegroundColor Green
    }
    else {
        Write-Host "✗ Docker is not installed or not in PATH" -ForegroundColor Red
        $allGood = $false
    }
}
catch {
    Write-Host "✗ Docker is not available" -ForegroundColor Red
    $allGood = $false
}

# Check 2: Java
Write-Host "[2/5] Checking Java..." -ForegroundColor Yellow
try {
    $javaVersion = java -version 2>&1 | Select-String "version"
    if ($javaVersion) {
        Write-Host "✓ Java is installed: $($javaVersion.Line)" -ForegroundColor Green
    }
    else {
        Write-Host "✗ Java is not installed or not in PATH" -ForegroundColor Red
        $allGood = $false
    }
}
catch {
    Write-Host "✗ Java is not available" -ForegroundColor Red
    $allGood = $false
}

# Check 3: Node.js
Write-Host "[3/5] Checking Node.js..." -ForegroundColor Yellow
try {
    $nodeVersion = node --version 2>$null
    if ($nodeVersion) {
        Write-Host "✓ Node.js is installed: $nodeVersion" -ForegroundColor Green
    }
    else {
        Write-Host "✗ Node.js is not installed or not in PATH" -ForegroundColor Red
        $allGood = $false
    }
}
catch {
    Write-Host "✗ Node.js is not available" -ForegroundColor Red
    $allGood = $false
}

# Check 4: PostgreSQL Container
Write-Host "[4/5] Checking PostgreSQL Container..." -ForegroundColor Yellow
try {
    $containerStatus = docker ps --filter "name=klb-postgres" --format "{{.Status}}" 2>$null
    if ($containerStatus -match "Up") {
        Write-Host "✓ PostgreSQL container is running" -ForegroundColor Green
    }
    else {
        Write-Host "⚠️ PostgreSQL container is not running" -ForegroundColor Yellow
        Write-Host "   Run: docker-compose up -d" -ForegroundColor Gray
    }
}
catch {
    Write-Host "⚠️ Could not check PostgreSQL container status" -ForegroundColor Yellow
}

# Check 5: Backend Health
Write-Host "[5/5] Checking Backend Health..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "http://localhost:8080/api/health" -Method GET -TimeoutSec 5 2>$null
    if ($response.status) {
        Write-Host "✓ Backend is running: $($response.status)" -ForegroundColor Green
    }
    else {
        Write-Host "⚠️ Backend is not responding" -ForegroundColor Yellow
        Write-Host "   Start with: .\mvnw.cmd spring-boot:run" -ForegroundColor Gray
    }
}
catch {
    Write-Host "⚠️ Backend is not running or not accessible" -ForegroundColor Yellow
    Write-Host "   Start with: .\mvnw.cmd spring-boot:run" -ForegroundColor Gray
}

Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan

if ($allGood) {
    Write-Host "🎉 All prerequisites are installed!" -ForegroundColor Green
    Write-Host ""
    Write-Host "To start the system:" -ForegroundColor Blue
    Write-Host "1. .\start-all.ps1" -ForegroundColor Gray
    Write-Host "   OR"
    Write-Host "2. Manual setup:" -ForegroundColor Gray
    Write-Host "   - docker-compose up -d" -ForegroundColor Gray
    Write-Host "   - .\mvnw.cmd spring-boot:run" -ForegroundColor Gray
    Write-Host "   - cd klb-frontend && npm start" -ForegroundColor Gray
}
else {
    Write-Host "❌ Some prerequisites are missing" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please install missing components:" -ForegroundColor Blue
    Write-Host "- Docker Desktop: https://www.docker.com/products/docker-desktop" -ForegroundColor Gray
    Write-Host "- Java 17+: https://adoptium.net/" -ForegroundColor Gray
    Write-Host "- Node.js 16+: https://nodejs.org/" -ForegroundColor Gray
}

Write-Host ""
Read-Host "Press Enter to exit"
