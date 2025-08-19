# KLB Account Management System - Start Script
Write-Host ""
Write-Host "====================================" -ForegroundColor Cyan
Write-Host " KLB Account Management System" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""

# Check if Docker is running
Write-Host "[1/3] Starting PostgreSQL Database..." -ForegroundColor Yellow
Set-Location "e:\dowload\klb-account-management\klb-account-management"

try {
    docker-compose up -d
    Write-Host "✓ Database started successfully" -ForegroundColor Green
}
catch {
    Write-Host "✗ Failed to start database. Is Docker running?" -ForegroundColor Red
    Read-Host "Press Enter to continue anyway"
}

Write-Host ""
Write-Host "[2/3] Starting Backend (Spring Boot)..." -ForegroundColor Yellow
Write-Host "Please wait for backend to start completely..." -ForegroundColor Gray

# Start backend in new window
Start-Process PowerShell -ArgumentList @(
    "-NoExit", 
    "-Command", 
    "Set-Location 'e:\dowload\klb-account-management\klb-account-management'; .\mvnw.cmd spring-boot:run"
) -WindowStyle Normal

Write-Host ""
Write-Host "[3/3] Installing Frontend Dependencies and Starting..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

Set-Location "e:\dowload\klb-account-management\klb-frontend"

try {
    npm install
    Write-Host "✓ Dependencies installed successfully" -ForegroundColor Green
}
catch {
    Write-Host "✗ Failed to install dependencies. Is Node.js installed?" -ForegroundColor Red
}

# Start frontend in new window
Start-Process PowerShell -ArgumentList @(
    "-NoExit", 
    "-Command", 
    "Set-Location 'e:\dowload\klb-account-management\klb-frontend'; npm start"
) -WindowStyle Normal

Write-Host ""
Write-Host "====================================" -ForegroundColor Green
Write-Host " Setup Complete!" -ForegroundColor Green
Write-Host "====================================" -ForegroundColor Green
Write-Host ""
Write-Host "🌐 Frontend: " -NoNewline; Write-Host "http://localhost:3000" -ForegroundColor Blue
Write-Host "🔧 Backend:  " -NoNewline; Write-Host "http://localhost:8080" -ForegroundColor Blue
Write-Host "🗄️ Database: " -NoNewline; Write-Host "localhost:5432" -ForegroundColor Blue
Write-Host ""
Write-Host "Wait a few moments for all services to start, then open your browser." -ForegroundColor Gray
Write-Host ""

Read-Host "Press Enter to exit"
