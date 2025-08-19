# # Circuit Breaker Test Script
# # Đây là script để test Circuit Breaker pattern

# # Test 1: Kiểm tra tài khoản được tạo bình thường khi customer service hoạt động
# echo "=== Test 1: Normal Operation ==="
# echo "Testing account creation with valid customer..."

# # Sử dụng curl để test API (cần JWT token)
# $headers = @{
#     "Content-Type"  = "application/json"
#     "Authorization" = "Bearer YOUR_JWT_TOKEN_HERE"
# }

# $body = @{
#     "accountType" = "SAVINGS"
#     "balance"     = 1000.0
# } | ConvertTo-Json

# try {
#     $response = Invoke-RestMethod -Uri "http://localhost:8090/api/accounts/1" -Method Post -Headers $headers -Body $body
#     Write-Host "✅ Account created successfully: $($response.accountNumber)" -ForegroundColor Green
# }
# catch {
#     Write-Host "❌ Error: $($_.Exception.Message)" W-ForegroundColor Red
# }

# echo ""
# echo "=== Test 2: Circuit Breaker Activation ==="
# echo "Stop customer-service and try to create account..."
# echo "Expected: Circuit breaker should activate after threshold is reached"

# # Simulate multiple failed requests
# for ($i = 1; $i -le 12; $i++) {
#     try {
#         echo "Request $i:"
#         $response = Invoke-RestMethod -Uri "http://localhost:8090/api/accounts/1" -Method Post -Headers $headers -Body $body
#         Write-Host "✅ Success" -ForegroundColor Green
#     }
#     catch {
#         $errorMessage = $_.Exception.Message
#         if ($errorMessage -like "*CB-CUST-001*") {
#             Write-Host "🔥 Circuit Breaker Activated!" -ForegroundColor Yellow
#         }
#         else {
#             Write-Host "❌ Error: $errorMessage" -ForegroundColor Red
#         }
#     }
#     Start-Sleep -Seconds 1
# }

# echo ""
# echo "=== Test 3: Circuit Breaker Recovery ==="
# echo "Start customer-service again and wait for recovery..."
# echo "Expected: Circuit breaker should recover after wait duration"

# Start-Sleep -Seconds 6  # Wait for circuit breaker to enter HALF_OPEN state

# for ($i = 1; $i -le 5; $i++) {
#     try {
#         echo "Recovery attempt $i:"
#         $response = Invoke-RestMethod -Uri "http://localhost:8090/api/accounts/1" -Method Post -Headers $headers -Body $body
#         Write-Host "✅ Circuit Breaker Recovered!" -ForegroundColor Green
#         break
#     }
#     catch {
#         Write-Host "❌ Still failing: $($_.Exception.Message)" -ForegroundColor Red
#     }
#     Start-Sleep -Seconds 2
# }

# echo ""
# echo "=== Circuit Breaker States ==="
# echo "CLOSED: Normal operation, requests pass through"
# echo "OPEN: Circuit breaker activated, requests fail fast"
# echo "HALF_OPEN: Testing if service has recovered"

# echo ""
# echo "=== Monitoring Endpoints ==="
# echo "Health: http://localhost:8090/actuator/health"
# echo "Metrics: http://localhost:8090/actuator/metrics/resilience4j.circuitbreaker.calls"
# echo "Circuit Breaker State: http://localhost:8090/actuator/circuitbreakerevents"
