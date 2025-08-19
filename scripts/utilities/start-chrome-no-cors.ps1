# Quick Fix: Chrome with CORS disabled for testing

Write-Host "🔧 Starting Chrome with CORS disabled for testing..." -ForegroundColor Yellow
Write-Host "This is for DEVELOPMENT/TESTING only!" -ForegroundColor Red

# Kill existing Chrome processes
Get-Process chrome -ErrorAction SilentlyContinue | Stop-Process -Force

# Create temp directory
$tempDir = "C:\temp\chrome_dev"
if (-not (Test-Path $tempDir)) {
    New-Item -ItemType Directory -Path $tempDir -Force
}

# Start Chrome with disabled security
$chromeArgs = @(
    "--disable-web-security",
    "--user-data-dir=`"$tempDir`"", 
    "--disable-features=VizDisplayCompositor",
    "--allow-running-insecure-content",
    "--disable-extensions",
    "http://localhost:8000/custom-login-demo-fixed.html"
)

# Find Chrome executable
$chromePaths = @(
    "${env:ProgramFiles}\Google\Chrome\Application\chrome.exe",
    "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
    "${env:LOCALAPPDATA}\Google\Chrome\Application\chrome.exe"
)

$chromeExe = $null
foreach ($path in $chromePaths) {
    if (Test-Path $path) {
        $chromeExe = $path
        break
    }
}

if ($chromeExe) {
    Write-Host "✅ Found Chrome at: $chromeExe" -ForegroundColor Green
    Write-Host "🚀 Starting Chrome with disabled CORS..." -ForegroundColor Blue
    
    # Start HTTP server in background
    Start-Job -ScriptBlock {
        Set-Location "E:\dowload\klb-account-management"
        python -m http.server 8000
    } -Name "HTTPServer"
    
    Start-Sleep -Seconds 2
    
    # Start Chrome
    & $chromeExe $chromeArgs
    
    Write-Host ""
    Write-Host "📱 TESTING INSTRUCTIONS:" -ForegroundColor Cyan
    Write-Host "========================" -ForegroundColor Blue
    Write-Host "1. Browser đã mở với CORS disabled" -ForegroundColor White
    Write-Host "2. Click 'testuser' button để điền thông tin" -ForegroundColor White
    Write-Host "3. Click 'Đăng nhập' - Lần này sẽ không có CORS error!" -ForegroundColor White
    Write-Host "4. Test thành công → Xem user info và JWT token" -ForegroundColor White
    Write-Host ""
    Write-Host "⚠️  CHÚ Ý:" -ForegroundColor Yellow
    Write-Host "- Chrome này chỉ để test, không dùng để browse bình thường" -ForegroundColor Red
    Write-Host "- Production cần dùng backend proxy (AuthProxyController)" -ForegroundColor Yellow
    
} else {
    Write-Host "❌ Chrome not found!" -ForegroundColor Red
    Write-Host "Manually open: http://localhost:8000/custom-login-demo-fixed.html" -ForegroundColor Yellow
}
