# KLB Frontend Startup Script
# This script provides multiple options to start the frontend

Write-Host "KLB Frontend Startup Options:" -ForegroundColor Green
Write-Host "1. Use built version (recommended - no warnings)" -ForegroundColor Yellow
Write-Host "2. Use development server (may show deprecation warnings)" -ForegroundColor Yellow
Write-Host "3. Use development server with warnings suppressed" -ForegroundColor Yellow

$choice = Read-Host "Enter your choice (1-3)"

switch ($choice) {
    "1" {
        Write-Host "Starting built frontend with serve..." -ForegroundColor Green
        npx --yes serve -s build -p 3000
    }
    "2" {
        Write-Host "Starting development server..." -ForegroundColor Green
        npm start
    }
    "3" {
        Write-Host "Starting development server with warnings suppressed..." -ForegroundColor Green
        $env:NODE_OPTIONS = "--no-deprecation"
        $env:DANGEROUSLY_DISABLE_HOST_CHECK = "true"
        npx --yes react-scripts start
    }
    default {
        Write-Host "Invalid choice. Using option 1 (built version)..." -ForegroundColor Red
        npx --yes serve -s build -p 3000
    }
}
