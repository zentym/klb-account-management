# Test admin user login
$headers = @{"Content-Type" = "application/x-www-form-urlencoded"}
$body = "grant_type=password&client_id=klb-frontend&username=admin&password=admin123"

try {
    $response = Invoke-RestMethod -Uri "http://localhost:8090/realms/Kienlongbank/protocol/openid-connect/token" -Method Post -Body $body -Headers $headers
    Write-Host "✅ Admin user login successful!" -ForegroundColor Green
    Write-Host "Token expires in: $($response.expires_in) seconds" -ForegroundColor White
} catch {
    Write-Host "❌ Admin user login failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Admin user may not exist. Using testuser only." -ForegroundColor Yellow
}
