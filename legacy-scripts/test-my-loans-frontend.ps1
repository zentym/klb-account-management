# Test Frontend - My Loans Page
# This script tests the new My Loans page functionality

Write-Host "🧪 Testing Frontend - My Loans Page Integration" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green

# Test 1: Check if MyLoansPage component exists
Write-Host "`n📝 Test 1: Checking MyLoansPage component..." -ForegroundColor Yellow
$myLoansPagePath = "klb-frontend\src\components\MyLoansPage.tsx"
if (Test-Path $myLoansPagePath) {
    Write-Host "✅ MyLoansPage.tsx exists" -ForegroundColor Green
}
else {
    Write-Host "❌ MyLoansPage.tsx not found" -ForegroundColor Red
}

# Test 2: Check if route is added to AppRouter
Write-Host "`n📝 Test 2: Checking route configuration..." -ForegroundColor Yellow
$routerPath = "klb-frontend\src\components\AppRouter.tsx"
if (Test-Path $routerPath) {
    $routerContent = Get-Content $routerPath -Raw
    if ($routerContent -match "/loans/my-loans") {
        Write-Host "✅ Route /loans/my-loans found in AppRouter.tsx" -ForegroundColor Green
    }
    else {
        Write-Host "❌ Route /loans/my-loans not found in AppRouter.tsx" -ForegroundColor Red
    }
    
    if ($routerContent -match "MyLoansPage") {
        Write-Host "✅ MyLoansPage import found in AppRouter.tsx" -ForegroundColor Green
    }
    else {
        Write-Host "❌ MyLoansPage import not found in AppRouter.tsx" -ForegroundColor Red
    }
}
else {
    Write-Host "❌ AppRouter.tsx not found" -ForegroundColor Red
}

# Test 3: Check if navigation link is added
Write-Host "`n📝 Test 3: Checking navigation menu..." -ForegroundColor Yellow
$navPath = "klb-frontend\src\components\Navigation.tsx"
if (Test-Path $navPath) {
    $navContent = Get-Content $navPath -Raw
    if ($navContent -match "/loans/my-loans") {
        Write-Host "✅ Navigation link to /loans/my-loans found" -ForegroundColor Green
    }
    else {
        Write-Host "❌ Navigation link to /loans/my-loans not found" -ForegroundColor Red
    }
}
else {
    Write-Host "❌ Navigation.tsx not found" -ForegroundColor Red
}

# Test 4: Check if dashboard has the new quick action
Write-Host "`n📝 Test 4: Checking dashboard quick actions..." -ForegroundColor Yellow
$dashboardPath = "klb-frontend\src\components\Dashboard.tsx"
if (Test-Path $dashboardPath) {
    $dashboardContent = Get-Content $dashboardPath -Raw
    if ($dashboardContent -match "Các khoản vay của tôi") {
        Write-Host "✅ Dashboard quick action for My Loans found" -ForegroundColor Green
    }
    else {
        Write-Host "❌ Dashboard quick action for My Loans not found" -ForegroundColor Red
    }
}
else {
    Write-Host "❌ Dashboard.tsx not found" -ForegroundColor Red
}

# Test 5: Check backend API endpoint
Write-Host "`n📝 Test 5: Checking backend API endpoint..." -ForegroundColor Yellow
$controllerPath = "kienlongbank-project\loan-service\src\main\java\com\kienlongbank\loan_service\controller\LoanController.java"
if (Test-Path $controllerPath) {
    $controllerContent = Get-Content $controllerPath -Raw
    if ($controllerContent -match "@GetMapping\(`"/customer/\{customerId\}`"\)") {
        Write-Host "✅ Backend API endpoint /customer/{customerId} found" -ForegroundColor Green
    }
    else {
        Write-Host "❌ Backend API endpoint /customer/{customerId} not found" -ForegroundColor Red
    }
    
    if ($controllerContent -match "isAdminOrManager" -and $controllerContent -match "isCurrentUser") {
        Write-Host "✅ Security helper methods found" -ForegroundColor Green
    }
    else {
        Write-Host "❌ Security helper methods not found" -ForegroundColor Red
    }
}
else {
    Write-Host "❌ LoanController.java not found" -ForegroundColor Red
}

Write-Host "`n🎉 Frontend My Loans Page Test Complete!" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green

Write-Host "`n📋 Next Steps:" -ForegroundColor Cyan
Write-Host "1. Start the backend services: cd kienlongbank-project && docker-compose up -d" -ForegroundColor White
Write-Host "2. Start the loan service: cd kienlongbank-project/loan-service && ./mvnw spring-boot:run" -ForegroundColor White
Write-Host "3. Start the frontend: cd klb-frontend && npm start" -ForegroundColor White
Write-Host "4. Login and navigate to 'Khoản vay của tôi' to test the functionality" -ForegroundColor White

Write-Host "`n🔗 Available URLs:" -ForegroundColor Cyan
Write-Host "- Frontend: http://localhost:3000" -ForegroundColor White
Write-Host "- My Loans Page: http://localhost:3000/loans/my-loans" -ForegroundColor White
Write-Host "- Backend API: http://localhost:8082/api/loans/customer/1" -ForegroundColor White
