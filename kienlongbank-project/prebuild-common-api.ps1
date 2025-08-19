# Pre-build script for common-api (PowerShell version)

Write-Host "🚀 Pre-building common-api module..." -ForegroundColor Green

Set-Location common-api
mvn clean install -DskipTests -q

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Common-api build completed!" -ForegroundColor Green
    Write-Host "📦 Artifact installed to local Maven repository" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "💡 Now you can build other services faster:" -ForegroundColor Yellow
    Write-Host "   docker-compose build loan-service" -ForegroundColor White
}
else {
    Write-Host "❌ Common-api build failed!" -ForegroundColor Red
    exit 1
}
