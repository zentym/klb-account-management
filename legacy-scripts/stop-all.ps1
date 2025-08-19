# KLB Account Management System - Stop Script
Write-Host ""
Write-Host "====================================" -ForegroundColor Red
Write-Host " KLB Account Management - STOP ALL" -ForegroundColor Red
Write-Host "====================================" -ForegroundColor Red
Write-Host ""

# Function to safely kill processes
function Stop-ProcessSafely {
    param(
        [string]$ProcessName,
        [string]$Description
    )
    
    try {
        $processes = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue
        if ($processes) {
            Write-Host "Stopping $Description..." -ForegroundColor Yellow
            $processes | ForEach-Object { 
                try {
                    $_.Kill()
                    Write-Host "✓ Stopped $($_.ProcessName) (PID: $($_.Id))" -ForegroundColor Green
                } catch {
                    Write-Host "✗ Failed to stop $($_.ProcessName) (PID: $($_.Id))" -ForegroundColor Red
                }
            }
        } else {
            Write-Host "No $Description processes running" -ForegroundColor Gray
        }
    } catch {
        Write-Host "No $Description processes found" -ForegroundColor Gray
    }
}

Write-Host "[1/4] Stopping Frontend (Node.js)..." -ForegroundColor Yellow
# Kill Node.js processes (React development server)
Stop-ProcessSafely -ProcessName "node" -Description "Node.js (Frontend)"

Write-Host ""
Write-Host "[2/4] Stopping Backend (Java)..." -ForegroundColor Yellow
# Kill Java processes (Spring Boot)
Stop-ProcessSafely -ProcessName "java" -Description "Java (Backend)"

Write-Host ""
Write-Host "[3/4] Stopping Maven processes..." -ForegroundColor Yellow
# Kill Maven wrapper processes
Stop-ProcessSafely -ProcessName "mvnw" -Description "Maven Wrapper"

Write-Host ""
Write-Host "[4/4] Stopping Database (Docker)..." -ForegroundColor Yellow
# Stop Docker containers
Set-Location "e:\dowload\klb-account-management\klb-account-management"
try {
    docker-compose down
    Write-Host "✓ Database containers stopped" -ForegroundColor Green
} catch {
    Write-Host "✗ Failed to stop database containers" -ForegroundColor Red
}

Write-Host ""
Write-Host "====================================" -ForegroundColor Green
Write-Host " All Services Stopped!" -ForegroundColor Green
Write-Host "====================================" -ForegroundColor Green
Write-Host ""

# Additional cleanup - kill any remaining npm or development server processes
Write-Host "Performing additional cleanup..." -ForegroundColor Yellow

# Kill any remaining npm processes
try {
    Get-Process | Where-Object { $_.ProcessName -like "*npm*" -or $_.MainWindowTitle -like "*React*" -or $_.MainWindowTitle -like "*KLB*" } | ForEach-Object {
        try {
            $_.Kill()
            Write-Host "✓ Cleaned up additional process: $($_.ProcessName)" -ForegroundColor Green
        } catch {
            # Process might have already been terminated
        }
    }
} catch {
    # No additional processes to clean up
}

Write-Host ""
Write-Host "To start services again, run:" -ForegroundColor Cyan
Write-Host "  .\start-all.ps1" -ForegroundColor White
Write-Host ""

Read-Host "Press Enter to exit"
