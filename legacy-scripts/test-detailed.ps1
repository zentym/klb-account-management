# Test với error handling chi tiết hơn
Write-Host "🔐 Testing with Detailed Error Handling" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan

$baseUrl = "http://localhost:8080"

# Test với thông tin rất đơn giản
$registerData = @{
    username = "test"
    password = "test"
} | ConvertTo-Json

Write-Host "📡 JSON being sent:" -ForegroundColor Yellow
Write-Host $registerData -ForegroundColor Gray

Write-Host "`n📡 Registering new user: test/test" -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/api/auth/register" -Method POST -ContentType "application/json" -Body $registerData -UseBasicParsing -Verbose
    Write-Host "✅ Registration successful!" -ForegroundColor Green
    Write-Host "Response: $($response | ConvertTo-Json)" -ForegroundColor Cyan
} catch {
    Write-Host "❌ Registration failed: $($_.Exception.Message)" -ForegroundColor Red
    
    # Try to get detailed error
    if ($_.Exception.Response) {
        $statusCode = $_.Exception.Response.StatusCode
        Write-Host "Status Code: $statusCode" -ForegroundColor Red
        
        try {
            $responseStream = $_.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($responseStream)
            $responseBody = $reader.ReadToEnd()
            Write-Host "Response Body: $responseBody" -ForegroundColor Red
        } catch {
            Write-Host "Could not read response body: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

Write-Host "`n🏁 Test completed!" -ForegroundColor Cyan
