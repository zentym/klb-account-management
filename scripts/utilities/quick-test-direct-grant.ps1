# Quick test for Direct Grant
Write-Host "🧪 Quick Direct Grant Test..." -ForegroundColor Blue

$headers = @{
    "Content-Type" = "application/x-www-form-urlencoded"
}

$body = "grant_type=password&client_id=klb-frontend&username=testuser&password=password123"

try {
    $response = Invoke-RestMethod -Uri "http://localhost:8090/realms/Kienlongbank/protocol/openid-connect/token" -Method Post -Body $body -Headers $headers
    Write-Host "✅ SUCCESS! Direct grant is working!" -ForegroundColor Green
    Write-Host "Token type: $($response.token_type)" -ForegroundColor White
    Write-Host "Expires in: $($response.expires_in) seconds" -ForegroundColor White
} catch {
    Write-Host "❌ Direct grant failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "Ready to test with custom login UI!" -ForegroundColor Green
