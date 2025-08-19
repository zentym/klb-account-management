# Monitor Docker Build Progress
param(
    [string]$ServiceName = "loan-service",
    [switch]$ShowLogs
)

Write-Host "🔍 Monitoring $ServiceName build progress..." -ForegroundColor Yellow

# Check if build is running
$buildProcess = Get-Process -Name "docker-compose" -ErrorAction SilentlyContinue
if ($buildProcess) {
    Write-Host "✅ Build process is running (PID: $($buildProcess.Id))" -ForegroundColor Green
} else {
    Write-Host "❌ No active build process found" -ForegroundColor Red
}

# Show current docker images size
Write-Host "`n📊 Current Docker Images:" -ForegroundColor Cyan
docker images | Select-String "loan-service|SIZE"

# Show docker system disk usage
Write-Host "`n💾 Docker System Usage:" -ForegroundColor Cyan
docker system df

if ($ShowLogs) {
    Write-Host "`n📝 Recent Docker Build Logs:" -ForegroundColor Cyan
    docker-compose logs --tail=20 $ServiceName
}

Write-Host "`n⏱️  Build Performance Tips:" -ForegroundColor Magenta
Write-Host "• Use BuildKit: $env:DOCKER_BUILDKIT=1" -ForegroundColor White
Write-Host "• Parallel builds: docker-compose build --parallel" -ForegroundColor White
Write-Host "• Clean cache: docker builder prune" -ForegroundColor White
