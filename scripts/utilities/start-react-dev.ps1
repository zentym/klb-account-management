# Start React Development with Custom Login

Write-Host "🚀 Starting KLB Frontend with Custom Login..." -ForegroundColor Green

# Step 1: Ensure containers are running
Write-Host "📋 Step 1: Checking services..." -ForegroundColor Yellow

Set-Location "kienlongbank-project"
docker-compose up -d keycloak postgres-db api-gateway
Set-Location ".."

Start-Sleep -Seconds 5

# Step 2: Start React dev server
Write-Host "📋 Step 2: Starting React development server..." -ForegroundColor Yellow

Set-Location "klb-frontend"

# Create temporary proxy configuration for development
$proxyConfig = @"
{
  "name": "klb-frontend-temp",
  "version": "0.1.0",
  "private": true,
  "proxy": "http://localhost:8090",
  "dependencies": $(Get-Content package.json | ConvertFrom-Json | Select-Object -ExpandProperty dependencies | ConvertTo-Json -Compress),
  "devDependencies": $(Get-Content package.json | ConvertFrom-Json | Select-Object -ExpandProperty devDependencies | ConvertTo-Json -Compress),
  "scripts": $(Get-Content package.json | ConvertFrom-Json | Select-Object -ExpandProperty scripts | ConvertTo-Json -Compress),
  "eslintConfig": $(Get-Content package.json | ConvertFrom-Json | Select-Object -ExpandProperty eslintConfig | ConvertTo-Json -Compress),
  "browserslist": $(Get-Content package.json | ConvertFrom-Json | Select-Object -ExpandProperty browserslist | ConvertTo-Json -Compress)
}
"@

# Backup original package.json
Copy-Item "package.json" "package.json.backup"

# Write temporary proxy config
$proxyConfig | Out-File "package.json" -Encoding UTF8

Write-Host ""
Write-Host "📱 DEVELOPMENT SETUP:" -ForegroundColor Cyan
Write-Host "=====================" -ForegroundColor Blue
Write-Host "✅ Keycloak: http://localhost:8090" -ForegroundColor White
Write-Host "✅ API Gateway: http://localhost:8080" -ForegroundColor White
Write-Host "✅ React App: http://localhost:3000" -ForegroundColor White
Write-Host "✅ Custom Login: http://localhost:3000/custom-login" -ForegroundColor White
Write-Host ""
Write-Host "🧪 TEST CREDENTIALS:" -ForegroundColor Yellow
Write-Host "- testuser / password123 (USER role)" -ForegroundColor White
Write-Host ""
Write-Host "🚀 Starting React dev server..." -ForegroundColor Green

# Start React dev server
npm start
