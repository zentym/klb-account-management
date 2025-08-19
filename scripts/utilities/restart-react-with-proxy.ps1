Write-Host "🔄 Restarting React with Keycloak proxy..." -ForegroundColor Yellow

# Kill existing React process
Get-Process node -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -eq "node" } | Stop-Process -Force

Write-Host "✅ Proxy updated to Keycloak (port 8090)" -ForegroundColor Green
Write-Host "📋 Restarting React development server..." -ForegroundColor Blue

Set-Location "klb-frontend"

Write-Host ""
Write-Host "📱 UPDATED CONFIGURATION:" -ForegroundColor Cyan
Write-Host "=========================" -ForegroundColor Blue
Write-Host "✅ React Proxy: http://localhost:8090 (Keycloak)" -ForegroundColor White
Write-Host "✅ Custom Login: http://localhost:3000/custom-login" -ForegroundColor White
Write-Host "✅ Test User: testuser / password123" -ForegroundColor White
Write-Host ""

npm start
