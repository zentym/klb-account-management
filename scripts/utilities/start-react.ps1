Write-Host "🚀 KLB React Development" -ForegroundColor Green

Write-Host "📋 Starting services..." -ForegroundColor Yellow
Set-Location "kienlongbank-project"
docker-compose up -d keycloak
Set-Location ".."

Write-Host "📋 Starting React app..." -ForegroundColor Yellow
Set-Location "klb-frontend"

Write-Host ""
Write-Host "📱 TEST CUSTOM LOGIN:" -ForegroundColor Cyan
Write-Host "Navigate to: http://localhost:3000/custom-login" -ForegroundColor White
Write-Host "Credentials: testuser / password123" -ForegroundColor White
Write-Host ""

npm start
