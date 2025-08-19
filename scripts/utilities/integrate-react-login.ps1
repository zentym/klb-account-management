# Integrate Custom Login to React App

Write-Host "🚀 Integrating Custom Login to React App..." -ForegroundColor Green

cd klb-frontend

# Install missing TypeScript types
Write-Host "📦 Installing TypeScript dependencies..." -ForegroundColor Yellow
npm install --save-dev @types/react @types/react-dom @types/node

Write-Host "✅ Dependencies installed!" -ForegroundColor Green

# Update package.json to include proxy for development
Write-Host "🔧 Updating package.json with Keycloak proxy..." -ForegroundColor Yellow

# Backup original package.json
Copy-Item "package.json" "package.json.backup"

# Read current package.json
$packageJson = Get-Content "package.json" | ConvertFrom-Json

# Add proxy configuration
$packageJson | Add-Member -NotePropertyName "proxy" -NotePropertyValue "http://localhost:8090" -Force

# Save updated package.json
$packageJson | ConvertTo-Json -Depth 10 | Set-Content "package.json"

Write-Host "✅ package.json updated with proxy configuration!" -ForegroundColor Green

Write-Host ""
Write-Host "📋 Next Steps:" -ForegroundColor Cyan
Write-Host "1. Update App.tsx to use CustomAuthProvider" -ForegroundColor White
Write-Host "2. Update AppRouter.tsx to add CustomLoginPage route" -ForegroundColor White
Write-Host "3. Test with: npm start" -ForegroundColor White
Write-Host "4. Navigate to: http://localhost:3000/custom-login" -ForegroundColor White
