# PowerShell script để khởi động databases cho microservices

Write-Host "🐳 Starting PostgreSQL databases for microservices..." -ForegroundColor Green

# Start the docker containers
Write-Host "Starting main account management database (port 5432)..." -ForegroundColor Yellow
Write-Host "Starting customer service database (port 5433)..." -ForegroundColor Yellow

docker-compose up -d postgres-db postgres-customer-db

Write-Host "⏳ Waiting for databases to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

Write-Host "📊 Checking database status..." -ForegroundColor Yellow
docker ps | Select-String postgres

Write-Host "✅ Database setup complete!" -ForegroundColor Green
Write-Host ""
Write-Host "🔗 Connection details:" -ForegroundColor Cyan
Write-Host "   Main Service DB: localhost:5432/account_management" -ForegroundColor White
Write-Host "   Customer Service DB: localhost:5433/customer_service_db" -ForegroundColor White
Write-Host "   Username: kienlong" -ForegroundColor White
Write-Host "   Password: notStrongPassword" -ForegroundColor White
Write-Host ""
Write-Host "🚀 You can now start your services:" -ForegroundColor Cyan
Write-Host "   1. Main service (port 8080): cd klb-account-management && mvn spring-boot:run" -ForegroundColor White
Write-Host "   2. Customer service (port 8082): cd customer-service/customer-service && mvn spring-boot:run" -ForegroundColor White
