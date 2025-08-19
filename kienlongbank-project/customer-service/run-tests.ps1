# Customer Service Test Runner Script
# Chạy Integration Tests cho CustomerController

Write-Host "🚀 Customer Service Integration Test Runner" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green

# Set location to customer-service directory
$customerServicePath = "E:\dowload\klb-account-management\kienlongbank-project\customer-service"

if (-Not (Test-Path $customerServicePath)) {
    Write-Host "❌ Customer service directory not found: $customerServicePath" -ForegroundColor Red
    exit 1
}

Set-Location $customerServicePath
Write-Host "📁 Working directory: $PWD" -ForegroundColor Cyan

# Check if Maven is available
try {
    $mavenVersion = mvn --version
    Write-Host "✅ Maven found" -ForegroundColor Green
}
catch {
    Write-Host "❌ Maven not found in PATH. Please install Maven first." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Choose test type to run:" -ForegroundColor Yellow
Write-Host "1. Integration Tests (Full Spring Context + H2 Database)" -ForegroundColor White
Write-Host "2. Unit Tests (Controller + Mock Service)" -ForegroundColor White  
Write-Host "3. All Tests" -ForegroundColor White
Write-Host "4. Test with Coverage Report" -ForegroundColor White
Write-Host "5. Clean and Test" -ForegroundColor White

$choice = Read-Host "Enter your choice (1-5)"

switch ($choice) {
    "1" {
        Write-Host "🧪 Running Integration Tests..." -ForegroundColor Blue
        mvn test -Dtest=CustomerControllerIntegrationTest -Dspring.profiles.active=test
    }
    "2" {
        Write-Host "🧪 Running Unit Tests..." -ForegroundColor Blue
        mvn test -Dtest=CustomerControllerUnitTest
    }
    "3" {
        Write-Host "🧪 Running All Tests..." -ForegroundColor Blue
        mvn test
    }
    "4" {
        Write-Host "🧪 Running Tests with Coverage..." -ForegroundColor Blue
        mvn test jacoco:report
        Write-Host "📊 Coverage report generated in target/site/jacoco/index.html" -ForegroundColor Green
    }
    "5" {
        Write-Host "🧹 Cleaning and Running Tests..." -ForegroundColor Blue
        mvn clean test
    }
    default {
        Write-Host "❌ Invalid choice. Running all tests by default..." -ForegroundColor Yellow
        mvn test
    }
}

Write-Host ""
Write-Host "📋 Test Results Summary:" -ForegroundColor Green
Write-Host "========================" -ForegroundColor Green

# Check if test results exist
$testResultsPath = "target\surefire-reports"
if (Test-Path $testResultsPath) {
    $xmlFiles = Get-ChildItem "$testResultsPath\TEST-*.xml" -ErrorAction SilentlyContinue
    
    if ($xmlFiles) {
        foreach ($xmlFile in $xmlFiles) {
            [xml]$testResult = Get-Content $xmlFile.FullName
            $testSuite = $testResult.testsuite
            
            Write-Host "📄 $($xmlFile.BaseName)" -ForegroundColor Cyan
            Write-Host "   Tests: $($testSuite.tests)" -ForegroundColor White
            Write-Host "   Passed: $($testSuite.tests - $testSuite.failures - $testSuite.errors)" -ForegroundColor Green
            Write-Host "   Failed: $($testSuite.failures)" -ForegroundColor Red
            Write-Host "   Errors: $($testSuite.errors)" -ForegroundColor Red
            Write-Host "   Time: $($testSuite.time)s" -ForegroundColor White
            Write-Host ""
        }
    }
    else {
        Write-Host "ℹ️ No test result files found" -ForegroundColor Yellow
    }
}
else {
    Write-Host "ℹ️ Test results directory not found" -ForegroundColor Yellow
}

# Check for compilation errors
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Tests failed or compilation errors occurred" -ForegroundColor Red
    Write-Host "💡 Check the output above for details" -ForegroundColor Yellow
}
else {
    Write-Host "✅ All tests completed successfully!" -ForegroundColor Green
}

Write-Host ""
Write-Host "🔧 Useful Commands:" -ForegroundColor Yellow
Write-Host "   mvn test -Dtest=ClassName#methodName  - Run specific test method" -ForegroundColor White
Write-Host "   mvn test -X                          - Run with debug output" -ForegroundColor White
Write-Host "   mvn surefire-report:report           - Generate HTML test report" -ForegroundColor White
Write-Host "   mvn clean                            - Clean build artifacts" -ForegroundColor White

Write-Host ""
Write-Host "📖 For more details, check: INTEGRATION_TESTS_README.md" -ForegroundColor Cyan

# Pause to keep window open
Write-Host "Press any key to continue..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
